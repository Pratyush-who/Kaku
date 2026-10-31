package handlers

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/google/uuid"

	"github.com/Pratyush-who/Kaku/backend/internal/middleware"
)

func TestBoardHandler_AuthValidation(t *testing.T) {
	handler := NewBoardHandler(nil, nil, 4)

	// 1. Unauthenticated access without context
	req := httptest.NewRequest(http.MethodGet, "/api/v1/boards/invalid-uuid", nil)
	w := httptest.NewRecorder()
	handler.HandleBoardByID(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401 Unauthorized, got %d", w.Code)
	}

	// 2. Authenticated context with empty board ID
	userID := uuid.New()
	reqEmpty := httptest.NewRequest(http.MethodGet, "/api/v1/boards/", nil)
	reqEmpty = reqEmpty.WithContext(context.WithValue(reqEmpty.Context(), middleware.UserContextKey, userID))
	wEmpty := httptest.NewRecorder()
	handler.HandleBoardByID(wEmpty, reqEmpty)

	if wEmpty.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 Bad Request for empty board ID, got %d", wEmpty.Code)
	}

	// 3. Authenticated context with invalid UUID
	reqInvalid := httptest.NewRequest(http.MethodGet, "/api/v1/boards/not-a-valid-uuid", nil)
	reqInvalid = reqInvalid.WithContext(context.WithValue(reqInvalid.Context(), middleware.UserContextKey, userID))
	wInvalid := httptest.NewRecorder()
	handler.HandleBoardByID(wInvalid, reqInvalid)

	if wInvalid.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 Bad Request for malformed UUID, got %d", wInvalid.Code)
	}
}

func TestBoardHandler_SharedBoardValidation(t *testing.T) {
	handler := NewBoardHandler(nil, nil, 4)

	// Accessing shared endpoint without share token
	req := httptest.NewRequest(http.MethodGet, "/api/v1/shared/boards/", nil)
	w := httptest.NewRecorder()
	handler.HandleSharedBoard(w, req)

	if w.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 Bad Request for empty share token, got %d", w.Code)
	}
}

func TestBoardHandler_TrashSubresourceRouting(t *testing.T) {
	projectHandler := NewProjectHandler(nil)
	userID := uuid.New()

	// GET /api/v1/projects/{projectId}/boards/trash with invalid project UUID
	req := httptest.NewRequest(http.MethodGet, "/api/v1/projects/bad-uuid/boards/trash", nil)
	req = req.WithContext(context.WithValue(req.Context(), middleware.UserContextKey, userID))
	w := httptest.NewRecorder()

	projectHandler.HandleProjectByID(w, req)
	if w.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 Bad Request for invalid project UUID, got %d", w.Code)
	}
}

func TestBoardHandler_MethodNotAllowedRoutes(t *testing.T) {
	// Verify invalid HTTP methods return appropriate statuses
	req := httptest.NewRequest(http.MethodPut, "/api/v1/shared/boards/token-xyz", strings.NewReader(`{}`))
	w := httptest.NewRecorder()
	handler := NewBoardHandler(nil, nil, 4)
	handler.HandleSharedBoard(w, req)

	// Should attempt lookup and fail with 404 since repo is nil or board doesn't exist
	if w.Code != http.StatusNotFound && w.Code != http.StatusInternalServerError {
		t.Fatalf("expected error status for shared board with nil repo, got %d", w.Code)
	}
}
