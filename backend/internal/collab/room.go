package collab

import (
	"context"
	"encoding/json"
	"log"
	"sync"
	"time"

	"github.com/google/uuid"

	"github.com/Pratyush-who/Kaku/backend/internal/models"
	"github.com/Pratyush-who/Kaku/backend/internal/repository"
)

type clientMessage struct {
	client  *Client
	message *InboundWSMessage
}

// Room manages active WebSocket clients on a specific board
type Room struct {
	boardID    uuid.UUID
	hub        *Hub
	repo       *repository.PostgresRepository
	clients    map[*Client]bool
	register   chan *Client
	unregister chan *Client
	inbound    chan *clientMessage
	colorIdx   int
	mu         sync.RWMutex
	stopChan   chan struct{}
}

func NewRoom(boardID uuid.UUID, hub *Hub, repo *repository.PostgresRepository) *Room {
	return &Room{
		boardID:    boardID,
		hub:        hub,
		repo:       repo,
		clients:    make(map[*Client]bool),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		inbound:    make(chan *clientMessage, 512),
		stopChan:   make(chan struct{}),
	}
}

func (r *Room) Run() {
	for {
		select {
		case <-r.stopChan:
			return

		case client := <-r.register:
			r.handleRegister(client)

		case client := <-r.unregister:
			r.handleUnregister(client)

		case cm := <-r.inbound:
			r.handleMessage(cm.client, cm.message)
		}
	}
}

func (r *Room) handleRegister(c *Client) {
	r.mu.Lock()
	// Assign color
	color := CollaboratorColors[r.colorIdx%len(CollaboratorColors)]
	r.colorIdx++
	c.info.Color = color
	c.info.ConnectedAt = time.Now()
	c.info.LastActiveAt = time.Now()

	r.clients[c] = true

	// Collect list of other active users
	allUsers := make([]models.ActiveCollaborator, 0, len(r.clients))
	for client := range r.clients {
		allUsers = append(allUsers, client.info)
	}
	r.mu.Unlock()

	// 1. Send ROOM_STATE to the joining user
	var revision int64 = 0
	if r.repo != nil {
		ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
		if board, err := r.repo.GetBoardByID(ctx, r.boardID); err == nil {
			revision = board.Revision
		}
		cancel()
	}

	c.SendJSON(OutboundWSMessage{
		Type:      TypeRoomState,
		Timestamp: time.Now().UnixMilli(),
		Payload: RoomStatePayload{
			BoardID:   r.boardID,
			Revision:  revision,
			Self:      c.info,
			Users:     allUsers,
			Timestamp: time.Now().UnixMilli(),
		},
	})

	// 2. Broadcast USER_JOINED to everyone else in the room
	r.broadcastToOthers(c, OutboundWSMessage{
		Type:      TypeUserJoined,
		SenderID:  c.info.UserID,
		Timestamp: time.Now().UnixMilli(),
		Payload: UserEventPayload{
			User: c.info,
		},
	})

	// Log join activity asynchronously
	if r.repo != nil {
		go func() {
			userUUID, err := uuid.Parse(c.info.UserID)
			if err == nil {
				actCtx, actCancel := context.WithTimeout(context.Background(), 3*time.Second)
				defer actCancel()
				_ = r.repo.LogBoardActivity(actCtx, &models.BoardActivity{
					BoardID:  r.boardID,
					UserID:   &userUUID,
					UserName: c.info.DisplayName,
					Action:   "joined_canvas",
					Details:  json.RawMessage(`{"role":"` + c.info.Role + `"}`),
				})
			}
		}()
	}
}

func (r *Room) handleUnregister(c *Client) {
	r.mu.Lock()
	if _, ok := r.clients[c]; ok {
		delete(r.clients, c)
		c.Close()
	}
	remaining := len(r.clients)
	r.mu.Unlock()

	// Broadcast USER_LEFT to remaining clients
	r.Broadcast(OutboundWSMessage{
		Type:      TypeUserLeft,
		SenderID:  c.info.UserID,
		Timestamp: time.Now().UnixMilli(),
		Payload: UserEventPayload{
			User: c.info,
		},
	})

	// Log leave activity asynchronously
	if r.repo != nil {
		go func() {
			userUUID, err := uuid.Parse(c.info.UserID)
			if err == nil {
				actCtx, actCancel := context.WithTimeout(context.Background(), 3*time.Second)
				defer actCancel()
				_ = r.repo.LogBoardActivity(actCtx, &models.BoardActivity{
					BoardID:  r.boardID,
					UserID:   &userUUID,
					UserName: c.info.DisplayName,
					Action:   "left_canvas",
				})
			}
		}()
	}

	if remaining == 0 && r.hub != nil {
		r.hub.RemoveRoom(r.boardID)
	}
}

func (r *Room) handleMessage(c *Client, msg *InboundWSMessage) {
	now := time.Now()

	r.mu.Lock()
	c.info.LastActiveAt = now
	r.mu.Unlock()

	switch msg.Type {
	case TypePing:
		c.SendJSON(OutboundWSMessage{
			Type:      TypePong,
			Timestamp: now.UnixMilli(),
		})

	case TypeCursorMove:
		var p CursorPayload
		if err := json.Unmarshal(msg.Payload, &p); err != nil {
			return
		}

		r.mu.Lock()
		c.info.CursorX = p.X
		c.info.CursorY = p.Y
		c.info.DrawingTool = p.Tool
		c.info.CurrentElementID = p.ElementID
		r.mu.Unlock()

		p.UserID = c.info.UserID
		p.Name = c.info.Name
		p.DisplayName = c.info.DisplayName
		p.Color = c.info.Color

		r.broadcastToOthers(c, OutboundWSMessage{
			Type:      TypeCursorUpdate,
			SenderID:  c.info.UserID,
			Timestamp: now.UnixMilli(),
			Payload:   p,
		})

	case TypeDrawingState:
		var p DrawingStatePayload
		if err := json.Unmarshal(msg.Payload, &p); err != nil {
			return
		}

		r.mu.Lock()
		c.info.IsDrawing = p.IsDrawing
		c.info.DrawingTool = p.Tool
		c.info.CurrentElementID = p.ElementID
		r.mu.Unlock()

		p.UserID = c.info.UserID
		p.DisplayName = c.info.DisplayName
		p.Color = c.info.Color

		r.broadcastToOthers(c, OutboundWSMessage{
			Type:      TypeUserDrawing,
			SenderID:  c.info.UserID,
			Timestamp: now.UnixMilli(),
			Payload:   p,
		})

	case TypeElementsChange:
		// Viewers cannot modify canvas elements
		if c.info.Role == "viewer" {
			c.SendJSON(OutboundWSMessage{
				Type:      TypeError,
				Timestamp: now.UnixMilli(),
				Payload:   "Viewers are read-only and cannot edit canvas elements",
			})
			return
		}

		var p ElementsChangePayload
		if err := json.Unmarshal(msg.Payload, &p); err != nil {
			return
		}

		userUUID, _ := uuid.Parse(c.info.UserID)

		// Stamp author provenance onto elements ("who who drew")
		for i := range p.Elements {
			p.Elements[i].BoardID = r.boardID
			if p.Elements[i].CreatedBy == nil && userUUID != uuid.Nil {
				p.Elements[i].CreatedBy = &userUUID
				p.Elements[i].CreatedByName = c.info.DisplayName
			}
			if userUUID != uuid.Nil {
				p.Elements[i].LastModifiedBy = &userUUID
				p.Elements[i].LastModifiedByName = c.info.DisplayName
			}
			p.Elements[i].UpdatedAt = now
		}

		p.SenderID = c.info.UserID
		p.SenderName = c.info.DisplayName

		// Broadcast to all other peers in the room
		r.broadcastToOthers(c, OutboundWSMessage{
			Type:      TypeElementsSync,
			SenderID:  c.info.UserID,
			Timestamp: now.UnixMilli(),
			Payload:   p,
		})

		// Asynchronously persist elements and log activity
		if r.repo != nil {
			go func(action string, elements []models.BoardElement, uID uuid.UUID, uName string) {
				ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
				defer cancel()

				switch action {
				case "delete":
					ids := make([]string, len(elements))
					for i, el := range elements {
						ids[i] = el.ID
					}
					var modifier *uuid.UUID
					if uID != uuid.Nil {
						modifier = &uID
					}
					if err := r.repo.SoftDeleteBoardElements(ctx, r.boardID, ids, modifier); err != nil {
						log.Printf("Failed to soft delete elements on board %s: %v", r.boardID, err)
					}
				default:
					if err := r.repo.UpsertBoardElements(ctx, r.boardID, elements); err != nil {
						log.Printf("Failed to upsert elements on board %s: %v", r.boardID, err)
					}
				}

				// Log draw activity
				if uID != uuid.Nil {
					detailObj, _ := json.Marshal(map[string]interface{}{
						"count":  len(elements),
						"action": action,
					})
					_ = r.repo.LogBoardActivity(ctx, &models.BoardActivity{
						BoardID:  r.boardID,
						UserID:   &uID,
						UserName: uName,
						Action:   "drew_elements",
						Details:  detailObj,
					})
				}
			}(p.Action, p.Elements, userUUID, c.info.DisplayName)
		}

	case TypeCanvasSaved:
		r.Broadcast(OutboundWSMessage{
			Type:      TypeCanvasSaved,
			SenderID:  c.info.UserID,
			Timestamp: now.UnixMilli(),
			Payload:   msg.Payload,
		})
	}
}

// Broadcast sends a message to all connected clients in this room
func (r *Room) Broadcast(msg OutboundWSMessage) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	for client := range r.clients {
		client.SendJSON(msg)
	}
}

// broadcastToOthers sends a message to everyone in room except sender
func (r *Room) broadcastToOthers(sender *Client, msg OutboundWSMessage) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	for client := range r.clients {
		if client != sender {
			client.SendJSON(msg)
		}
	}
}

// GetActiveUsers returns a snapshot of active collaborators currently in the room
func (r *Room) GetActiveUsers() []models.ActiveCollaborator {
	r.mu.RLock()
	defer r.mu.RUnlock()

	users := make([]models.ActiveCollaborator, 0, len(r.clients))
	for client := range r.clients {
		users = append(users, client.info)
	}
	return users
}

func (r *Room) Close() {
	close(r.stopChan)
	r.mu.Lock()
	defer r.mu.Unlock()
	for client := range r.clients {
		client.Close()
	}
	r.clients = make(map[*Client]bool)
}
