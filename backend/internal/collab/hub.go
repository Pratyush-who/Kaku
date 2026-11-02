package collab

import (
	"context"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	"golang.org/x/crypto/bcrypt"

	"github.com/Pratyush-who/Kaku/backend/internal/auth"
	"github.com/Pratyush-who/Kaku/backend/internal/httputil"
	"github.com/Pratyush-who/Kaku/backend/internal/models"
	"github.com/Pratyush-who/Kaku/backend/internal/repository"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		// Allow all origins for flexible web and desktop/mobile client connection
		return true
	},
}

// Hub manages multi-room board collaborative sessions
type Hub struct {
	repo         *repository.PostgresRepository
	tokenService *auth.TokenService
	rooms        map[uuid.UUID]*Room
	mu           sync.RWMutex
}

func NewHub(repo *repository.PostgresRepository, tokenService *auth.TokenService) *Hub {
	return &Hub{
		repo:         repo,
		tokenService: tokenService,
		rooms:        make(map[uuid.UUID]*Room),
	}
}

// GetOrCreateRoom finds or initializes the room for a board
func (h *Hub) GetOrCreateRoom(boardID uuid.UUID) *Room {
	h.mu.Lock()
	defer h.mu.Unlock()

	if room, exists := h.rooms[boardID]; exists {
		return room
	}

	room := NewRoom(boardID, h, h.repo)
	h.rooms[boardID] = room
	go room.Run()
	return room
}

// RemoveRoom closes and deletes an idle room
func (h *Hub) RemoveRoom(boardID uuid.UUID) {
	h.mu.Lock()
	defer h.mu.Unlock()

	if room, exists := h.rooms[boardID]; exists {
		room.Close()
		delete(h.rooms, boardID)
	}
}

// GetActiveUsers returns current active collaborators on a board
func (h *Hub) GetActiveUsers(boardID uuid.UUID) []models.ActiveCollaborator {
	h.mu.RLock()
	room, exists := h.rooms[boardID]
	h.mu.RUnlock()

	if !exists {
		return []models.ActiveCollaborator{}
	}
	return room.GetActiveUsers()
}

// BroadcastToBoard sends a message to all users on a board if room is active
func (h *Hub) BroadcastToBoard(boardID uuid.UUID, msg OutboundWSMessage) {
	h.mu.RLock()
	room, exists := h.rooms[boardID]
	h.mu.RUnlock()

	if exists {
		room.Broadcast(msg)
	}
}

// ServeWS handles WebSocket connection upgrades for board collaboration
// Path: /api/v1/boards/{boardId}/ws
func (h *Hub) ServeWS(w http.ResponseWriter, r *http.Request) {
	// Extract board ID from path
	path := strings.TrimPrefix(r.URL.Path, "/api/v1/boards/")
	parts := strings.Split(strings.Trim(path, "/"), "/")
	if len(parts) == 0 || parts[0] == "" {
		httputil.Error(w, http.StatusBadRequest, "Board ID is required")
		return
	}

	boardID, err := uuid.Parse(parts[0])
	if err != nil {
		httputil.Error(w, http.StatusBadRequest, "Invalid board UUID format")
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
	defer cancel()

	board, err := h.repo.GetBoardByID(ctx, boardID)
	if err != nil {
		httputil.Error(w, http.StatusNotFound, "Board not found")
		return
	}

	if board.IsTrashed {
		httputil.Error(w, http.StatusGone, "Board is in trash")
		return
	}

	// Determine authentication & permissions
	var clientInfo models.ActiveCollaborator
	authenticated := false

	// 1. Try Bearer token from query parameter or header
	tokenStr := r.URL.Query().Get("token")
	if tokenStr == "" {
		authHeader := r.Header.Get("Authorization")
		if strings.HasPrefix(authHeader, "Bearer ") {
			tokenStr = strings.TrimPrefix(authHeader, "Bearer ")
		}
	}

	if tokenStr != "" {
		claims, err := h.tokenService.ValidateToken(tokenStr)
		if err == nil {
			userID := claims.UserID
			role, roleErr := h.repo.GetUserProjectRole(ctx, board.ProjectID, userID)
			if roleErr == nil {
				user, uErr := h.repo.GetUserByID(ctx, userID)
				if uErr == nil {
					clientInfo = models.ActiveCollaborator{
						UserID:       userID.String(),
						Name:         user.Name,
						DisplayName:  user.DisplayName,
						AvatarURL:    user.AvatarURL,
						Role:         string(role),
						ConnectedAt:  time.Now(),
						LastActiveAt: time.Now(),
					}
					authenticated = true
				}
			}
		}
	}

	// 2. If not authenticated via user token, check public share link
	if !authenticated {
		shareToken := r.URL.Query().Get("shareToken")
		if shareToken == "" && board.IsPublic {
			shareToken = board.ShareToken
		}

		if shareToken != "" && shareToken == board.ShareToken {
			// Check password if board is protected
			if board.PasswordHash != "" {
				pwd := r.URL.Query().Get("password")
				if pwd == "" || bcrypt.CompareHashAndPassword([]byte(board.PasswordHash), []byte(pwd)) != nil {
					httputil.Error(w, http.StatusUnauthorized, "Password required or invalid for this board")
					return
				}
			}

			randomNum := rand.Intn(9000) + 1000
			clientInfo = models.ActiveCollaborator{
				UserID:       fmt.Sprintf("guest-%d", randomNum),
				Name:         fmt.Sprintf("Guest %d", randomNum),
				DisplayName:  fmt.Sprintf("Guest %d", randomNum),
				AvatarURL:    "",
				Role:         string(board.PublicRole),
				ConnectedAt:  time.Now(),
				LastActiveAt: time.Now(),
			}
			authenticated = true
		}
	}

	// 3. If still not authenticated, check parent project's public share settings
	if !authenticated {
		projShareToken := r.URL.Query().Get("projectShareToken")
		if projShareToken == "" {
			projShareToken = r.URL.Query().Get("shareToken")
		}

		parentProj, pErr := h.repo.GetProjectByID(ctx, board.ProjectID)
		if pErr == nil && parentProj.IsPublic && parentProj.ShareToken != "" && (projShareToken == parentProj.ShareToken || parentProj.IsPublic) {
			randomNum := rand.Intn(9000) + 1000
			clientInfo = models.ActiveCollaborator{
				UserID:       fmt.Sprintf("project-guest-%d", randomNum),
				Name:         fmt.Sprintf("Guest %d", randomNum),
				DisplayName:  fmt.Sprintf("Guest %d", randomNum),
				AvatarURL:    "",
				Role:         string(parentProj.PublicRole),
				ConnectedAt:  time.Now(),
				LastActiveAt: time.Now(),
			}
			authenticated = true
		}
	}

	if !authenticated {
		httputil.Error(w, http.StatusForbidden, "Unauthorized: valid token or share link required")
		return
	}

	// Upgrade HTTP to WebSocket
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("WS upgrade failed for board %s: %v", boardID, err)
		return
	}

	room := h.GetOrCreateRoom(boardID)
	client := NewClient(room, conn, clientInfo)

	room.register <- client

	go client.WritePump()
	go client.ReadPump()
}
