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

func TestProjectHandler_AuthAndValidation(t *testing.T) {
	handler := NewProjectHandler(nil)

	// 1. Unauthenticated access to /api/v1/projects
	req := httptest.NewRequest(http.MethodGet, "/api/v1/projects", nil)
	w := httptest.NewRecorder()
	handler.HandleProjects(w, req)
	if w.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401 Unauthorized, got %d", w.Code)
	}

	// 2. Authenticated access to create project with empty body
	userID := uuid.New()
	reqCreate := httptest.NewRequest(http.MethodPost, "/api/v1/projects", strings.NewReader(`{"name":""}`))
	reqCreate = reqCreate.WithContext(context.WithValue(reqCreate.Context(), middleware.UserContextKey, userID))
	wCreate := httptest.NewRecorder()
	handler.HandleProjects(wCreate, reqCreate)
	if wCreate.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 Bad Request for empty project name, got %d", wCreate.Code)
	}

	// 3. Authenticated access with invalid project UUID
	reqInvalid := httptest.NewRequest(http.MethodGet, "/api/v1/projects/not-a-uuid", nil)
	reqInvalid = reqInvalid.WithContext(context.WithValue(reqInvalid.Context(), middleware.UserContextKey, userID))
	wInvalid := httptest.NewRecorder()
	handler.HandleProjectByID(wInvalid, reqInvalid)
	if wInvalid.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 Bad Request for malformed UUID, got %d", wInvalid.Code)
	}
}

func TestProjectHandler_SearchUsersValidation(t *testing.T) {
	handler := NewProjectHandler(nil)

	// 1. Unauthenticated search
	req := httptest.NewRequest(http.MethodGet, "/api/v1/users/search?q=alice", nil)
	w := httptest.NewRecorder()
	handler.HandleSearchUsers(w, req)
	if w.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401 Unauthorized, got %d", w.Code)
	}

	// 2. Authenticated search with empty query returns empty list
	userID := uuid.New()
	reqEmpty := httptest.NewRequest(http.MethodGet, "/api/v1/users/search?q=", nil)
	reqEmpty = reqEmpty.WithContext(context.WithValue(reqEmpty.Context(), middleware.UserContextKey, userID))
	wEmpty := httptest.NewRecorder()
	handler.HandleSearchUsers(wEmpty, reqEmpty)
	if wEmpty.Code != http.StatusOK {
		t.Fatalf("expected 200 OK, got %d", wEmpty.Code)
	}
	if strings.TrimSpace(wEmpty.Body.String()) != "[]" {
		t.Fatalf("expected empty json array [], got %s", wEmpty.Body.String())
	}
}

func TestProjectHandler_GlobalSearchValidation(t *testing.T) {
	handler := NewProjectHandler(nil)

	// 1. Unauthenticated global search
	req := httptest.NewRequest(http.MethodGet, "/api/v1/search?q=diagram", nil)
	w := httptest.NewRecorder()
	handler.HandleGlobalSearch(w, req)
	if w.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401 Unauthorized, got %d", w.Code)
	}

	// 2. Authenticated search with empty query returns empty results
	userID := uuid.New()
	reqEmpty := httptest.NewRequest(http.MethodGet, "/api/v1/search?q=", nil)
	reqEmpty = reqEmpty.WithContext(context.WithValue(reqEmpty.Context(), middleware.UserContextKey, userID))
	wEmpty := httptest.NewRecorder()
	handler.HandleGlobalSearch(wEmpty, reqEmpty)
	if wEmpty.Code != http.StatusOK {
		t.Fatalf("expected 200 OK, got %d", wEmpty.Code)
	}
}

func TestProjectHandler_SharedProjectValidation(t *testing.T) {
	handler := NewProjectHandler(nil)

	// 1. Missing share token
	req := httptest.NewRequest(http.MethodGet, "/api/v1/shared/projects/", nil)
	w := httptest.NewRecorder()
	handler.HandleSharedProject(w, req)
	if w.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 Bad Request for empty share token, got %d", w.Code)
	}

	// 2. Join without authentication
	reqJoin := httptest.NewRequest(http.MethodPost, "/api/v1/shared/projects/sample-token/join", nil)
	wJoin := httptest.NewRecorder()
	handler.HandleSharedProject(wJoin, reqJoin)
	if wJoin.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401 Unauthorized for joining without auth, got %d", wJoin.Code)
	}
}

