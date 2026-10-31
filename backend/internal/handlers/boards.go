package handlers

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"

	"github.com/Pratyush-who/Kaku/backend/internal/collab"
	"github.com/Pratyush-who/Kaku/backend/internal/httputil"
	"github.com/Pratyush-who/Kaku/backend/internal/middleware"
	"github.com/Pratyush-who/Kaku/backend/internal/models"
	"github.com/Pratyush-who/Kaku/backend/internal/repository"
)

type BoardHandler struct {
	repo       *repository.PostgresRepository
	hub        *collab.Hub
	bcryptCost int
}

func NewBoardHandler(repo *repository.PostgresRepository, hub *collab.Hub, bcryptCost int) *BoardHandler {
	if bcryptCost <= 0 {
		bcryptCost = bcrypt.DefaultCost
	}
	return &BoardHandler{
		repo:       repo,
		hub:        hub,
		bcryptCost: bcryptCost,
	}
}

type UpdateBoardRequest struct {
	Name        string `json:"name,omitempty"`
	Description string `json:"description,omitempty"`
	Thumbnail   string `json:"thumbnail,omitempty"`
}

type SaveBoardContentRequest struct {
	ExpectedRevision int64           `json:"expectedRevision"`
	Content          json.RawMessage `json:"content"`
	Viewport         json.RawMessage `json:"viewport,omitempty"`
	CreateSnapshot   bool            `json:"createSnapshot,omitempty"`
	SnapshotTitle    string          `json:"snapshotTitle,omitempty"`
}

type SaveBoardContentResponse struct {
	BoardID  uuid.UUID `json:"boardId"`
	Revision int64     `json:"revision"`
	Message  string    `json:"message"`
}

type BoardDetailResponse struct {
	*models.Board
	ActiveCollaboratorsCount int                       `json:"activeCollaboratorsCount"`
	ActiveCollaborators      []models.ActiveCollaborator `json:"activeCollaborators,omitempty"`
	UserRole                 models.ProjectRole        `json:"userRole"`
}

type ShareSettingsRequest struct {
	IsPublic        *bool              `json:"isPublic,omitempty"`
	PublicRole      models.ProjectRole `json:"publicRole,omitempty"`
	Password        string             `json:"password,omitempty"`
	RemovePassword  bool               `json:"removePassword,omitempty"`
	RegenerateToken bool               `json:"regenerateToken,omitempty"`
}

type ShareSettingsResponse struct {
	BoardID     uuid.UUID          `json:"boardId"`
	ShareToken  string             `json:"shareToken"`
	ShareURL    string             `json:"shareUrl"`
	IsPublic    bool               `json:"isPublic"`
	PublicRole  models.ProjectRole `json:"publicRole"`
	HasPassword bool               `json:"hasPassword"`
}

type ElementsBatchRequest struct {
	Elements []models.BoardElement `json:"elements"`
}

type DeleteElementsRequest struct {
	ElementIDs []string `json:"elementIds"`
}

type CreateSnapshotRequest struct {
	Title       string `json:"title"`
	Description string `json:"description,omitempty"`
}

func (h *BoardHandler) HandleBoardByID(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		httputil.Error(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	path := strings.TrimPrefix(r.URL.Path, "/api/v1/boards/")
	path = strings.TrimPrefix(path, "/api/v1/boards")
	trimmed := strings.Trim(path, "/")
	if trimmed == "" {
		httputil.Error(w, http.StatusBadRequest, "Board ID is required")
		return
	}
	parts := strings.Split(trimmed, "/")

	boardID, err := uuid.Parse(parts[0])
	if err != nil {
		httputil.Error(w, http.StatusBadRequest, "Invalid board UUID format")
		return
	}

	if h.repo == nil {
		httputil.Error(w, http.StatusInternalServerError, "Database unavailable")
		return
	}

	board, err := h.repo.GetBoardByID(r.Context(), boardID)
	if err != nil {
		httputil.Error(w, http.StatusNotFound, "Board not found")
		return
	}

	// Verify user permissions on parent project
	role, err := h.repo.GetUserProjectRole(r.Context(), board.ProjectID, userID)
	if err != nil {
		if errors.Is(err, repository.ErrForbidden) {
			httputil.Error(w, http.StatusForbidden, "You do not have access to this board")
			return
		}
		httputil.Error(w, http.StatusInternalServerError, "Database error")
		return
	}

	// Route based on subpath
	if len(parts) == 1 {
		h.handleBoardRoot(w, r, board, userID, role)
		return
	}

	switch parts[1] {
	case "content":
		h.handleBoardContent(w, r, board, userID, role)
	case "autosave":
		h.handleBoardAutosave(w, r, board, userID, role)
	case "duplicate":
		h.handleBoardDuplicate(w, r, board, userID, role)
	case "trash":
		h.handleBoardTrash(w, r, board, userID, role)
	case "restore":
		h.handleBoardRestore(w, r, board, userID, role)
	case "permanent":
		h.handleBoardPermanentDelete(w, r, board, userID, role)
	case "elements":
		h.handleBoardElements(w, r, board, userID, role)
	case "collaborators":
		h.handleBoardCollaborators(w, r, board)
	case "share":
		h.handleBoardShare(w, r, board, userID, role)
	case "history":
		h.handleBoardHistory(w, r, board, userID, role, parts[2:])
	case "activities":
		h.handleBoardActivities(w, r, board)
	default:
		httputil.Error(w, http.StatusNotFound, "Endpoint not found")
	}
}

func (h *BoardHandler) handleBoardRoot(w http.ResponseWriter, r *http.Request, board *models.Board, userID uuid.UUID, role models.ProjectRole) {
	switch r.Method {
	case http.MethodGet:
		activeUsers := []models.ActiveCollaborator{}
		if h.hub != nil {
			activeUsers = h.hub.GetActiveUsers(board.ID)
		}
		httputil.JSON(w, http.StatusOK, BoardDetailResponse{
			Board:                    board,
			ActiveCollaboratorsCount: len(activeUsers),
			ActiveCollaborators:      activeUsers,
			UserRole:                 role,
		})

	case http.MethodPatch:
		if role != models.RoleOwner && role != models.RoleEditor {
			httputil.Error(w, http.StatusForbidden, "Insufficient permissions to update board")
			return
		}
		var req UpdateBoardRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			httputil.Error(w, http.StatusBadRequest, "Invalid request body")
			return
		}
		name := strings.TrimSpace(req.Name)
		desc := req.Description
		thumb := req.Thumbnail
		if desc == "" && req.Name != "" && req.Thumbnail == "" {
			desc = "__KEEP__"
		}
		if thumb == "" && (req.Name != "" || req.Description != "") {
			thumb = "__KEEP__"
		}

		if err := h.repo.UpdateBoardMetadata(r.Context(), board.ID, name, desc, thumb); err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to update board")
			return
		}
		updated, _ := h.repo.GetBoardByID(r.Context(), board.ID)
		httputil.JSON(w, http.StatusOK, updated)

	case http.MethodDelete:
		// Default DELETE soft-deletes to trash
		if role != models.RoleOwner && role != models.RoleEditor {
			httputil.Error(w, http.StatusForbidden, "Insufficient permissions to delete board")
			return
		}
		if err := h.repo.TrashBoard(r.Context(), board.ID); err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to move board to trash")
			return
		}
		httputil.JSON(w, http.StatusOK, map[string]string{"message": "Board moved to trash"})

	default:
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
	}
}

func (h *BoardHandler) handleBoardTrash(w http.ResponseWriter, r *http.Request, board *models.Board, userID uuid.UUID, role models.ProjectRole) {
	if r.Method != http.MethodPost {
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	if role != models.RoleOwner && role != models.RoleEditor {
		httputil.Error(w, http.StatusForbidden, "Insufficient permissions to trash board")
		return
	}
	if err := h.repo.TrashBoard(r.Context(), board.ID); err != nil {
		httputil.Error(w, http.StatusInternalServerError, "Failed to trash board")
		return
	}
	httputil.JSON(w, http.StatusOK, map[string]string{"message": "Board moved to trash successfully"})
}

func (h *BoardHandler) handleBoardRestore(w http.ResponseWriter, r *http.Request, board *models.Board, userID uuid.UUID, role models.ProjectRole) {
	if r.Method != http.MethodPost {
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	if role != models.RoleOwner && role != models.RoleEditor {
		httputil.Error(w, http.StatusForbidden, "Insufficient permissions to restore board")
		return
	}
	if err := h.repo.RestoreBoard(r.Context(), board.ID); err != nil {
		httputil.Error(w, http.StatusInternalServerError, "Failed to restore board")
		return
	}
	restored, _ := h.repo.GetBoardByID(r.Context(), board.ID)
	httputil.JSON(w, http.StatusOK, restored)
}

func (h *BoardHandler) handleBoardPermanentDelete(w http.ResponseWriter, r *http.Request, board *models.Board, userID uuid.UUID, role models.ProjectRole) {
	if r.Method != http.MethodDelete {
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	if role != models.RoleOwner {
		httputil.Error(w, http.StatusForbidden, "Only project owners can permanently delete boards")
		return
	}
	if err := h.repo.DeleteBoard(r.Context(), board.ID); err != nil {
		httputil.Error(w, http.StatusInternalServerError, "Failed to permanently delete board")
		return
	}
	httputil.JSON(w, http.StatusOK, map[string]string{"message": "Board permanently deleted"})
}

func (h *BoardHandler) handleBoardContent(w http.ResponseWriter, r *http.Request, board *models.Board, userID uuid.UUID, role models.ProjectRole) {
	if r.Method != http.MethodPut {
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	if role != models.RoleOwner && role != models.RoleEditor {
		httputil.Error(w, http.StatusForbidden, "Viewers cannot modify board content")
		return
	}

	var req SaveBoardContentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httputil.Error(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if len(req.Content) == 0 {
		httputil.Error(w, http.StatusBadRequest, "Content payload cannot be empty")
		return
	}

	newRev, err := h.repo.UpdateBoardContentWithSnapshot(
		r.Context(),
		board.ID,
		req.Content,
		req.Viewport,
		req.ExpectedRevision,
		req.CreateSnapshot,
		req.SnapshotTitle,
		&userID,
	)
	if err != nil {
		if errors.Is(err, repository.ErrConflict) {
			httputil.Error(w, http.StatusConflict, "Conflict: board revision has changed on the server. Please reload or merge.")
			return
		}
		httputil.Error(w, http.StatusInternalServerError, "Failed to persist board content")
		return
	}

	// Notify active WebSocket clients of saved canvas revision
	if h.hub != nil {
		h.hub.BroadcastToBoard(board.ID, collab.OutboundWSMessage{
			Type:      collab.TypeCanvasSaved,
			SenderID:  userID.String(),
			Timestamp: time.Now().UnixMilli(),
			Payload: map[string]interface{}{
				"boardId":  board.ID,
				"revision": newRev,
			},
		})
	}

	httputil.JSON(w, http.StatusOK, SaveBoardContentResponse{
		BoardID:  board.ID,
		Revision: newRev,
		Message:  "Board content updated successfully",
	})
}

func (h *BoardHandler) handleBoardAutosave(w http.ResponseWriter, r *http.Request, board *models.Board, userID uuid.UUID, role models.ProjectRole) {
	if r.Method != http.MethodPost {
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	if role != models.RoleOwner && role != models.RoleEditor {
		httputil.Error(w, http.StatusForbidden, "Viewers cannot autosave board content")
		return
	}

	var req SaveBoardContentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httputil.Error(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if len(req.Content) == 0 {
		httputil.Error(w, http.StatusBadRequest, "Content payload cannot be empty")
		return
	}

	newRev, err := h.repo.UpdateBoardContent(r.Context(), board.ID, req.Content, req.Viewport, req.ExpectedRevision)
	if err != nil {
		if errors.Is(err, repository.ErrConflict) {
			httputil.Error(w, http.StatusConflict, "Conflict: board revision has changed. Please sync.")
			return
		}
		httputil.Error(w, http.StatusInternalServerError, "Failed to autosave board content")
		return
	}

	httputil.JSON(w, http.StatusOK, SaveBoardContentResponse{
		BoardID:  board.ID,
		Revision: newRev,
		Message:  "Autosaved successfully",
	})
}

func (h *BoardHandler) handleBoardDuplicate(w http.ResponseWriter, r *http.Request, board *models.Board, userID uuid.UUID, role models.ProjectRole) {
	if r.Method != http.MethodPost {
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	if role != models.RoleOwner && role != models.RoleEditor {
		httputil.Error(w, http.StatusForbidden, "Only owners and editors can duplicate boards")
		return
	}

	var req struct {
		Name string `json:"name"`
	}
	_ = json.NewDecoder(r.Body).Decode(&req)

	clonedBoard, err := h.repo.DuplicateBoard(r.Context(), board.ID, userID, strings.TrimSpace(req.Name))
	if err != nil {
		httputil.Error(w, http.StatusInternalServerError, "Failed to duplicate board")
		return
	}

	httputil.JSON(w, http.StatusCreated, clonedBoard)
}

func (h *BoardHandler) handleBoardElements(w http.ResponseWriter, r *http.Request, board *models.Board, userID uuid.UUID, role models.ProjectRole) {
	switch r.Method {
	case http.MethodGet:
		elements, err := h.repo.GetBoardElements(r.Context(), board.ID)
		if err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to fetch canvas elements")
			return
		}
		httputil.JSON(w, http.StatusOK, elements)

	case http.MethodPost:
		if role != models.RoleOwner && role != models.RoleEditor {
			httputil.Error(w, http.StatusForbidden, "Viewers cannot modify canvas elements")
			return
		}

		var req ElementsBatchRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			httputil.Error(w, http.StatusBadRequest, "Invalid request body")
			return
		}

		user, _ := h.repo.GetUserByID(r.Context(), userID)
		userName := "User"
		if user != nil {
			userName = user.DisplayName
		}

		for i := range req.Elements {
			req.Elements[i].BoardID = board.ID
			if req.Elements[i].CreatedBy == nil {
				req.Elements[i].CreatedBy = &userID
				req.Elements[i].CreatedByName = userName
			}
			req.Elements[i].LastModifiedBy = &userID
			req.Elements[i].LastModifiedByName = userName
		}

		if err := h.repo.UpsertBoardElements(r.Context(), board.ID, req.Elements); err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to save canvas elements")
			return
		}

		httputil.JSON(w, http.StatusOK, map[string]interface{}{
			"message": "Elements saved successfully",
			"count":   len(req.Elements),
		})

	case http.MethodDelete:
		if role != models.RoleOwner && role != models.RoleEditor {
			httputil.Error(w, http.StatusForbidden, "Viewers cannot delete canvas elements")
			return
		}

		var req DeleteElementsRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			httputil.Error(w, http.StatusBadRequest, "Invalid request body")
			return
		}

		if err := h.repo.SoftDeleteBoardElements(r.Context(), board.ID, req.ElementIDs, &userID); err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to delete canvas elements")
			return
		}

		httputil.JSON(w, http.StatusOK, map[string]interface{}{
			"message": "Elements deleted successfully",
			"count":   len(req.ElementIDs),
		})

	default:
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
	}
}

func (h *BoardHandler) handleBoardCollaborators(w http.ResponseWriter, r *http.Request, board *models.Board) {
	if r.Method != http.MethodGet {
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	activeUsers := []models.ActiveCollaborator{}
	if h.hub != nil {
		activeUsers = h.hub.GetActiveUsers(board.ID)
	}

	contributors, err := h.repo.GetBoardContributors(r.Context(), board.ID)
	if err != nil {
		httputil.Error(w, http.StatusInternalServerError, "Failed to fetch contributors")
		return
	}

	httputil.JSON(w, http.StatusOK, models.BoardCollaboratorsResponse{
		ActiveUsers:  activeUsers,
		Contributors: contributors,
	})
}

func (h *BoardHandler) handleBoardShare(w http.ResponseWriter, r *http.Request, board *models.Board, userID uuid.UUID, role models.ProjectRole) {
	shareURL := fmt.Sprintf("/shared/boards/%s", board.ShareToken)

	switch r.Method {
	case http.MethodGet:
		httputil.JSON(w, http.StatusOK, ShareSettingsResponse{
			BoardID:     board.ID,
			ShareToken:  board.ShareToken,
			ShareURL:    shareURL,
			IsPublic:    board.IsPublic,
			PublicRole:  board.PublicRole,
			HasPassword: board.HasPassword,
		})

	case http.MethodPost:
		if role != models.RoleOwner && role != models.RoleEditor {
			httputil.Error(w, http.StatusForbidden, "Only owners and editors can configure board sharing")
			return
		}

		var req ShareSettingsRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			httputil.Error(w, http.StatusBadRequest, "Invalid request body")
			return
		}

		isPublic := board.IsPublic
		if req.IsPublic != nil {
			isPublic = *req.IsPublic
		}

		publicRole := board.PublicRole
		if req.PublicRole == models.RoleViewer || req.PublicRole == models.RoleEditor {
			publicRole = req.PublicRole
		}

		newShareToken := ""
		if req.RegenerateToken {
			newShareToken = uuid.New().String()
		}

		newPasswordHash := "__KEEP__"
		if req.RemovePassword {
			newPasswordHash = ""
		} else if strings.TrimSpace(req.Password) != "" {
			hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), h.bcryptCost)
			if err != nil {
				httputil.Error(w, http.StatusInternalServerError, "Failed to hash board password")
				return
			}
			newPasswordHash = string(hash)
		}

		if err := h.repo.UpdateBoardShareSettings(r.Context(), board.ID, isPublic, publicRole, newShareToken, newPasswordHash); err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to update share settings")
			return
		}

		updated, err := h.repo.GetBoardByID(r.Context(), board.ID)
		if err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to load updated board")
			return
		}

		httputil.JSON(w, http.StatusOK, ShareSettingsResponse{
			BoardID:     updated.ID,
			ShareToken:  updated.ShareToken,
			ShareURL:    fmt.Sprintf("/shared/boards/%s", updated.ShareToken),
			IsPublic:    updated.IsPublic,
			PublicRole:  updated.PublicRole,
			HasPassword: updated.HasPassword,
		})

	default:
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
	}
}

func (h *BoardHandler) handleBoardHistory(w http.ResponseWriter, r *http.Request, board *models.Board, userID uuid.UUID, role models.ProjectRole, remaining []string) {
	if len(remaining) == 0 {
		switch r.Method {
		case http.MethodGet:
			versions, err := h.repo.ListBoardVersions(r.Context(), board.ID)
			if err != nil {
				httputil.Error(w, http.StatusInternalServerError, "Failed to fetch version history")
				return
			}
			httputil.JSON(w, http.StatusOK, versions)

		case http.MethodPost:
			if role != models.RoleOwner && role != models.RoleEditor {
				httputil.Error(w, http.StatusForbidden, "Viewers cannot create version snapshots")
				return
			}
			var req CreateSnapshotRequest
			if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
				httputil.Error(w, http.StatusBadRequest, "Invalid request body")
				return
			}
			req.Title = strings.TrimSpace(req.Title)
			if req.Title == "" {
				httputil.Error(w, http.StatusBadRequest, "Snapshot title is required")
				return
			}
			version := &models.BoardVersion{
				BoardID:     board.ID,
				Title:       req.Title,
				Description: req.Description,
				Content:     board.Content,
				Viewport:    board.Viewport,
				CreatedBy:   &userID,
			}
			if err := h.repo.CreateBoardVersion(r.Context(), version); err != nil {
				httputil.Error(w, http.StatusInternalServerError, "Failed to create snapshot")
				return
			}
			httputil.JSON(w, http.StatusCreated, version)

		default:
			httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		}
		return
	}

	// /api/v1/boards/{boardId}/history/{versionNumber}
	verNum, err := strconv.Atoi(remaining[0])
	if err != nil {
		httputil.Error(w, http.StatusBadRequest, "Invalid version number")
		return
	}

	if len(remaining) == 1 {
		if r.Method != http.MethodGet {
			httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
			return
		}
		version, err := h.repo.GetBoardVersionByNumber(r.Context(), board.ID, verNum)
		if err != nil {
			httputil.Error(w, http.StatusNotFound, "Version snapshot not found")
			return
		}
		httputil.JSON(w, http.StatusOK, version)
		return
	}

	// /api/v1/boards/{boardId}/history/{versionNumber}/restore
	if len(remaining) == 2 && remaining[1] == "restore" {
		if r.Method != http.MethodPost {
			httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
			return
		}
		if role != models.RoleOwner && role != models.RoleEditor {
			httputil.Error(w, http.StatusForbidden, "Viewers cannot restore board versions")
			return
		}
		restored, err := h.repo.RestoreBoardVersion(r.Context(), board.ID, verNum, &userID)
		if err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to restore version")
			return
		}
		httputil.JSON(w, http.StatusOK, restored)
		return
	}

	httputil.Error(w, http.StatusNotFound, "Endpoint not found")
}

func (h *BoardHandler) handleBoardActivities(w http.ResponseWriter, r *http.Request, board *models.Board) {
	if r.Method != http.MethodGet {
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	limit := 50
	if l := r.URL.Query().Get("limit"); l != "" {
		if val, err := strconv.Atoi(l); err == nil && val > 0 {
			limit = val
		}
	}
	activities, err := h.repo.ListBoardActivities(r.Context(), board.ID, limit)
	if err != nil {
		httputil.Error(w, http.StatusInternalServerError, "Failed to fetch activities")
		return
	}
	httputil.JSON(w, http.StatusOK, activities)
}

// HandleSharedBoard handles public / shared link access: /api/v1/shared/boards/{shareToken}
func (h *BoardHandler) HandleSharedBoard(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/api/v1/shared/boards/")
	shareToken := strings.Trim(path, "/")
	if shareToken == "" {
		httputil.Error(w, http.StatusBadRequest, "Share token is required")
		return
	}

	if h.repo == nil {
		httputil.Error(w, http.StatusInternalServerError, "Database unavailable")
		return
	}

	board, err := h.repo.GetBoardByShareToken(r.Context(), shareToken)
	if err != nil {
		httputil.Error(w, http.StatusNotFound, "Shared board not found or link has expired")
		return
	}

	// Verify password if protected
	if board.HasPassword {
		password := r.URL.Query().Get("password")
		if password == "" && r.Method == http.MethodPost {
			var body struct {
				Password string `json:"password"`
			}
			_ = json.NewDecoder(r.Body).Decode(&body)
			password = body.Password
		}
		if password == "" || bcrypt.CompareHashAndPassword([]byte(board.PasswordHash), []byte(password)) != nil {
			httputil.Error(w, http.StatusUnauthorized, "Password required or incorrect")
			return
		}
	}

	activeUsers := []models.ActiveCollaborator{}
	if h.hub != nil {
		activeUsers = h.hub.GetActiveUsers(board.ID)
	}

	httputil.JSON(w, http.StatusOK, BoardDetailResponse{
		Board:                    board,
		ActiveCollaboratorsCount: len(activeUsers),
		ActiveCollaborators:      activeUsers,
		UserRole:                 board.PublicRole,
	})
}
