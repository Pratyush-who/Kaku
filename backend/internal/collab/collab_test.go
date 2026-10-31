package collab

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"

	"github.com/Pratyush-who/Kaku/backend/internal/models"
)

func TestCollabRoom_CollaborationFlow(t *testing.T) {
	boardID := uuid.New()
	hub := NewHub(nil, nil)
	room := NewRoom(boardID, hub, nil)
	go room.Run()
	defer room.Close()

	// Setup a test HTTP server with WS upgrade
	s := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		conn, err := upgrader.Upgrade(w, r, nil)
		if err != nil {
			t.Fatalf("upgrade error: %v", err)
			return
		}
		userName := r.URL.Query().Get("user")
		role := r.URL.Query().Get("role")
		if role == "" {
			role = "editor"
		}
		clientInfo := models.ActiveCollaborator{
			UserID:      userName + "-id",
			Name:        userName,
			DisplayName: userName + " Display",
			Role:        role,
		}
		client := NewClient(room, conn, clientInfo)
		room.register <- client
		go client.WritePump()
		go client.ReadPump()
	}))
	defer s.Close()

	wsURL := "ws" + strings.TrimPrefix(s.URL, "http")

	// 1. Connect Client A (Alice)
	connA, _, err := websocket.DefaultDialer.Dial(wsURL+"?user=Alice&role=editor", nil)
	if err != nil {
		t.Fatalf("failed to connect client A: %v", err)
	}
	defer connA.Close()

	// Client A should receive ROOM_STATE
	var msgA OutboundWSMessage
	if err := connA.ReadJSON(&msgA); err != nil {
		t.Fatalf("failed to read initial message for Alice: %v", err)
	}
	if msgA.Type != TypeRoomState {
		t.Fatalf("expected ROOM_STATE for Alice, got %s", msgA.Type)
	}

	// 2. Connect Client B (Bob)
	connB, _, err := websocket.DefaultDialer.Dial(wsURL+"?user=Bob&role=editor", nil)
	if err != nil {
		t.Fatalf("failed to connect client B: %v", err)
	}
	defer connB.Close()

	// Client B receives ROOM_STATE
	var msgB OutboundWSMessage
	if err := connB.ReadJSON(&msgB); err != nil {
		t.Fatalf("failed to read initial message for Bob: %v", err)
	}
	if msgB.Type != TypeRoomState {
		t.Fatalf("expected ROOM_STATE for Bob, got %s", msgB.Type)
	}

	// Alice should receive USER_JOINED when Bob connects
	var joinMsg OutboundWSMessage
	if err := connA.ReadJSON(&joinMsg); err != nil {
		t.Fatalf("failed to read join notification for Alice: %v", err)
	}
	if joinMsg.Type != TypeUserJoined {
		t.Fatalf("expected USER_JOINED for Alice, got %s", joinMsg.Type)
	}

	// Verify active users count
	users := room.GetActiveUsers()
	if len(users) != 2 {
		t.Fatalf("expected 2 active users in room, got %d", len(users))
	}

	// 3. Test Live Cursor Synchronization: Alice moves cursor
	cursorPayload, _ := json.Marshal(CursorPayload{
		X:    150.5,
		Y:    320.0,
		Tool: "pencil",
	})
	if err := connA.WriteJSON(InboundWSMessage{
		Type:    TypeCursorMove,
		Payload: cursorPayload,
	}); err != nil {
		t.Fatalf("failed to send cursor move from Alice: %v", err)
	}

	// Bob should receive CURSOR_UPDATE from Alice
	var cursorUpdate OutboundWSMessage
	if err := connB.ReadJSON(&cursorUpdate); err != nil {
		t.Fatalf("failed to read cursor update on Bob: %v", err)
	}
	if cursorUpdate.Type != TypeCursorUpdate {
		t.Fatalf("expected CURSOR_UPDATE, got %s", cursorUpdate.Type)
	}
	if cursorUpdate.SenderID != "Alice-id" {
		t.Fatalf("expected sender Alice-id, got %s", cursorUpdate.SenderID)
	}

	// 4. Test Live Drawing Indicator ("who is drawing"): Alice starts drawing a rectangle
	drawPayload, _ := json.Marshal(DrawingStatePayload{
		IsDrawing: true,
		Tool:      "rectangle",
		ElementID: "elem_rect_1",
	})
	if err := connA.WriteJSON(InboundWSMessage{
		Type:    TypeDrawingState,
		Payload: drawPayload,
	}); err != nil {
		t.Fatalf("failed to send drawing state from Alice: %v", err)
	}

	// Bob should receive USER_DRAWING
	var drawUpdate OutboundWSMessage
	if err := connB.ReadJSON(&drawUpdate); err != nil {
		t.Fatalf("failed to read drawing update on Bob: %v", err)
	}
	if drawUpdate.Type != TypeUserDrawing {
		t.Fatalf("expected USER_DRAWING, got %s", drawUpdate.Type)
	}

	// 5. Test Element Synchronization ("who who drew"): Alice creates elements
	elementsPayload, _ := json.Marshal(ElementsChangePayload{
		Action: "create",
		Elements: []models.BoardElement{
			{
				ID:          "elem_rect_1",
				Type:        "rectangle",
				X:           100,
				Y:           100,
				Width:       200,
				Height:      150,
				StrokeColor: "#FF0000",
			},
		},
	})
	if err := connA.WriteJSON(InboundWSMessage{
		Type:    TypeElementsChange,
		Payload: elementsPayload,
	}); err != nil {
		t.Fatalf("failed to send elements change from Alice: %v", err)
	}

	// Bob should receive ELEMENTS_SYNC
	var syncUpdate OutboundWSMessage
	if err := connB.ReadJSON(&syncUpdate); err != nil {
		t.Fatalf("failed to read elements sync on Bob: %v", err)
	}
	if syncUpdate.Type != TypeElementsSync {
		t.Fatalf("expected ELEMENTS_SYNC, got %s", syncUpdate.Type)
	}

	// 6. Test Disconnect Presence: Alice disconnects
	_ = connA.Close()

	// Bob should receive USER_LEFT
	var leftUpdate OutboundWSMessage
	_ = connB.SetReadDeadline(time.Now().Add(2 * time.Second))
	if err := connB.ReadJSON(&leftUpdate); err != nil {
		t.Fatalf("failed to read user left on Bob: %v", err)
	}
	if leftUpdate.Type != TypeUserLeft {
		t.Fatalf("expected USER_LEFT, got %s", leftUpdate.Type)
	}
}
