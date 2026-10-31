package collab

import (
	"encoding/json"
	"log"
	"sync"
	"time"

	"github.com/gorilla/websocket"

	"github.com/Pratyush-who/Kaku/backend/internal/models"
)

const (
	writeWait      = 10 * time.Second
	pongWait       = 60 * time.Second
	pingPeriod     = (pongWait * 9) / 10
	maxMessageSize = 2 * 1024 * 1024 // 2MB to support complex drawings and vector paths
)

// Client represents a connected WebSocket user in a board room
type Client struct {
	room     *Room
	conn     *websocket.Conn
	send     chan []byte
	info     models.ActiveCollaborator
	isClosed bool
	mu       sync.Mutex
}

func NewClient(room *Room, conn *websocket.Conn, info models.ActiveCollaborator) *Client {
	return &Client{
		room: room,
		conn: conn,
		send: make(chan []byte, 256),
		info: info,
	}
}

func (c *Client) ReadPump() {
	defer func() {
		c.room.unregister <- c
		c.conn.Close()
	}()

	c.conn.SetReadLimit(maxMessageSize)
	_ = c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error {
		_ = c.conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	for {
		_, rawMsg, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure, websocket.CloseNormalClosure) {
				log.Printf("WS client read error: %v", err)
			}
			break
		}

		var inMsg InboundWSMessage
		if err := json.Unmarshal(rawMsg, &inMsg); err != nil {
			c.SendJSON(OutboundWSMessage{
				Type:      TypeError,
				Timestamp: time.Now().UnixMilli(),
				Payload:   "Invalid message format",
			})
			continue
		}

		c.room.inbound <- &clientMessage{
			client:  c,
			message: &inMsg,
		}
	}
}

func (c *Client) WritePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case msg, ok := <-c.send:
			_ = c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				// The room closed the channel.
				_ = c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := c.conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			if _, err := w.Write(msg); err != nil {
				return
			}

			// Batch queued messages into current frame
			n := len(c.send)
			for i := 0; i < n; i++ {
				_, _ = w.Write([]byte{'\n'})
				_, _ = w.Write(<-c.send)
			}

			if err := w.Close(); err != nil {
				return
			}

		case <-ticker.C:
			_ = c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

// SendJSON encodes and enqueues a message for this client
func (c *Client) SendJSON(v interface{}) {
	data, err := json.Marshal(v)
	if err != nil {
		return
	}

	c.mu.Lock()
	defer c.mu.Unlock()

	if c.isClosed {
		return
	}

	select {
	case c.send <- data:
	default:
		// Queue full, drop or close
	}
}

func (c *Client) Close() {
	c.mu.Lock()
	defer c.mu.Unlock()
	if !c.isClosed {
		c.isClosed = true
		close(c.send)
	}
}
