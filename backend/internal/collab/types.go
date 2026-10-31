package collab

import (
	"encoding/json"

	"github.com/google/uuid"

	"github.com/Pratyush-who/Kaku/backend/internal/models"
)

// Message Type constants
const (
	TypeUserJoined     = "USER_JOINED"
	TypeUserLeft       = "USER_LEFT"
	TypeRoomState      = "ROOM_STATE"
	TypeCursorMove     = "CURSOR_MOVE"
	TypeCursorUpdate   = "CURSOR_UPDATE"
	TypeDrawingState   = "DRAWING_STATE"
	TypeUserDrawing    = "USER_DRAWING"
	TypeElementsChange = "ELEMENTS_CHANGE"
	TypeElementsSync   = "ELEMENTS_SYNC"
	TypeCanvasSaved    = "CANVAS_SAVED"
	TypePing           = "PING"
	TypePong           = "PONG"
	TypeError          = "ERROR"
)

// InboundWSMessage is incoming message from a client
type InboundWSMessage struct {
	Type    string          `json:"type"`
	Payload json.RawMessage `json:"payload"`
}

// OutboundWSMessage is sent to clients
type OutboundWSMessage struct {
	Type      string      `json:"type"`
	SenderID  string      `json:"senderId,omitempty"`
	Timestamp int64       `json:"timestamp"`
	Payload   interface{} `json:"payload"`
}

// CursorPayload payload for CURSOR_MOVE / CURSOR_UPDATE
type CursorPayload struct {
	UserID      string  `json:"userId,omitempty"`
	Name        string  `json:"name,omitempty"`
	DisplayName string  `json:"displayName,omitempty"`
	Color       string  `json:"color,omitempty"`
	X           float64 `json:"x"`
	Y           float64 `json:"y"`
	Tool        string  `json:"tool,omitempty"`
	ElementID   string  `json:"elementId,omitempty"`
}

// DrawingStatePayload payload for DRAWING_STATE / USER_DRAWING
type DrawingStatePayload struct {
	UserID        string          `json:"userId,omitempty"`
	DisplayName   string          `json:"displayName,omitempty"`
	Color         string          `json:"color,omitempty"`
	IsDrawing     bool            `json:"isDrawing"`
	Tool          string          `json:"tool"` // rectangle, ellipse, freedraw, arrow, line, text
	ElementID     string          `json:"elementId,omitempty"`
	PreviewPoints json.RawMessage `json:"previewPoints,omitempty"` // in-progress strokes
}

// ElementsChangePayload payload for ELEMENTS_CHANGE / ELEMENTS_SYNC
type ElementsChangePayload struct {
	Action     string                `json:"action"` // "create", "update", "delete"
	Elements   []models.BoardElement `json:"elements"`
	SenderID   string                `json:"senderId,omitempty"`
	SenderName string                `json:"senderName,omitempty"`
}

// RoomStatePayload payload sent when user connects to a room
type RoomStatePayload struct {
	BoardID   uuid.UUID                   `json:"boardId"`
	Revision  int64                       `json:"revision"`
	Self      models.ActiveCollaborator   `json:"self"`
	Users     []models.ActiveCollaborator `json:"users"`
	Timestamp int64                       `json:"timestamp"`
}

// UserEventPayload payload for user join/leave
type UserEventPayload struct {
	User models.ActiveCollaborator `json:"user"`
}

// Curated collaborator cursor colors
var CollaboratorColors = []string{
	"#FF5722", // Deep Orange
	"#2196F3", // Blue
	"#4CAF50", // Green
	"#9C27B0", // Purple
	"#E91E63", // Pink
	"#00BCD4", // Cyan
	"#FF9800", // Amber
	"#3F51B5", // Indigo
	"#009688", // Teal
	"#795548", // Brown
}
