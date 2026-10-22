package handlers

import (
	"bytes"
	"context"
	"encoding/json"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"net/textproto"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/Pratyush-who/Kaku/backend/internal/auth"
	"github.com/Pratyush-who/Kaku/backend/internal/middleware"
	"github.com/Pratyush-who/Kaku/backend/internal/models"
)

func TestProfileAuthValidation(t *testing.T) {
	handler := NewProfileHandler(nil, nil, 4, t.TempDir())

	// Test unauthenticated access to /api/v1/me
	req := httptest.NewRequest(http.MethodGet, "/api/v1/me", nil)
	w := httptest.NewRecorder()
	handler.HandleMe(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401 Unauthorized without auth context, got %d", w.Code)
	}

	// Test unauthenticated access to /api/v1/me/stats
	reqSub := httptest.NewRequest(http.MethodGet, "/api/v1/me/stats", nil)
	wSub := httptest.NewRecorder()
	handler.HandleMeSubpaths(wSub, reqSub)

	if wSub.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401 Unauthorized without auth context, got %d", wSub.Code)
	}
}

func TestProfileUnknownSubpath(t *testing.T) {
	handler := NewProfileHandler(nil, nil, 4, t.TempDir())

	userID := uuid.New()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/me/nonexistent-route", nil)
	req = req.WithContext(context.WithValue(req.Context(), middleware.UserContextKey, userID))
	w := httptest.NewRecorder()

	handler.HandleMeSubpaths(w, req)

	if w.Code != http.StatusNotFound {
		t.Fatalf("expected 404 Not Found for unknown subpath, got %d", w.Code)
	}
}

func TestProfilePasswordValidation(t *testing.T) {
	handler := NewProfileHandler(nil, nil, 4, t.TempDir())
	userID := uuid.New()

	// 1. Empty body
	req := httptest.NewRequest(http.MethodPost, "/api/v1/me/password", strings.NewReader(`{}`))
	req = req.WithContext(context.WithValue(req.Context(), middleware.UserContextKey, userID))
	w := httptest.NewRecorder()
	handler.HandleMeSubpaths(w, req)
	if w.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 Bad Request for empty password fields, got %d", w.Code)
	}

	// 2. Short new password
	reqShort := httptest.NewRequest(http.MethodPost, "/api/v1/me/password", strings.NewReader(`{"currentPassword":"oldPassword123","newPassword":"short"}`))
	reqShort = reqShort.WithContext(context.WithValue(reqShort.Context(), middleware.UserContextKey, userID))
	wShort := httptest.NewRecorder()
	handler.HandleMeSubpaths(wShort, reqShort)
	if wShort.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 Bad Request for password < 8 characters, got %d", wShort.Code)
	}

	// 3. Same password
	reqSame := httptest.NewRequest(http.MethodPost, "/api/v1/me/password", strings.NewReader(`{"currentPassword":"samePassword123","newPassword":"samePassword123"}`))
	reqSame = reqSame.WithContext(context.WithValue(reqSame.Context(), middleware.UserContextKey, userID))
	wSame := httptest.NewRecorder()
	handler.HandleMeSubpaths(wSame, reqSame)
	if wSame.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 Bad Request when new password equals current password, got %d", wSame.Code)
	}
}

func TestProfileEmailValidation(t *testing.T) {
	handler := NewProfileHandler(nil, nil, 4, t.TempDir())
	userID := uuid.New()

	// 1. Invalid email format
	reqInvalid := httptest.NewRequest(http.MethodPost, "/api/v1/me/email", strings.NewReader(`{"newEmail":"not-an-email","password":"secretPassword123"}`))
	reqInvalid = reqInvalid.WithContext(context.WithValue(reqInvalid.Context(), middleware.UserContextKey, userID))
	wInvalid := httptest.NewRecorder()
	handler.HandleMeSubpaths(wInvalid, reqInvalid)
	if wInvalid.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 Bad Request for invalid email format, got %d", wInvalid.Code)
	}

	// 2. Missing password
	reqNoPass := httptest.NewRequest(http.MethodPost, "/api/v1/me/email", strings.NewReader(`{"newEmail":"user@example.com","password":""}`))
	reqNoPass = reqNoPass.WithContext(context.WithValue(reqNoPass.Context(), middleware.UserContextKey, userID))
	wNoPass := httptest.NewRecorder()
	handler.HandleMeSubpaths(wNoPass, reqNoPass)
	if wNoPass.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 Bad Request for missing password, got %d", wNoPass.Code)
	}
}

func TestProfilePreferencesValidation(t *testing.T) {
	handler := NewProfileHandler(nil, nil, 4, t.TempDir())
	userID := uuid.New()

	// Invalid JSON string (array instead of object or malformed JSON)
	req := httptest.NewRequest(http.MethodPatch, "/api/v1/me/preferences", strings.NewReader(`not-json`))
	req = req.WithContext(context.WithValue(req.Context(), middleware.UserContextKey, userID))
	w := httptest.NewRecorder()
	handler.HandleMeSubpaths(w, req)
	if w.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 Bad Request for invalid JSON in preferences, got %d", w.Code)
	}
}

func TestProfileAvatarMultipartUnsupportedType(t *testing.T) {
	tempDir := t.TempDir()
	handler := NewProfileHandler(nil, nil, 4, tempDir)
	userID := uuid.New()

	// Prepare multipart form with non-image file (e.g. text file)
	var body bytes.Buffer
	writer := multipart.NewWriter(&body)
	h := make(textproto.MIMEHeader)
	h.Set("Content-Disposition", `form-data; name="avatar"; filename="test.txt"`)
	h.Set("Content-Type", "text/plain")
	part, err := writer.CreatePart(h)
	if err != nil {
		t.Fatalf("failed to create form part: %v", err)
	}
	_, _ = part.Write([]byte("this is plain text, not an image"))
	writer.Close()

	req := httptest.NewRequest(http.MethodPost, "/api/v1/me/avatar", &body)
	req.Header.Set("Content-Type", writer.FormDataContentType())
	req = req.WithContext(context.WithValue(req.Context(), middleware.UserContextKey, userID))
	w := httptest.NewRecorder()

	handler.HandleMeSubpaths(w, req)
	if w.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 Bad Request for unsupported file type, got %d", w.Code)
	}
}

func TestProfileModelsSerialization(t *testing.T) {
	userID := uuid.New()
	now := time.Now().UTC()

	user := &models.User{
		ID:          userID,
		Name:        "Test User",
		Email:       "test@example.com",
		DisplayName: "Tester",
		AvatarURL:   "https://example.com/avatar.png",
		Bio:         "Software architect and designer",
		Preferences: models.DefaultPreferences,
		CreatedAt:   now,
		UpdatedAt:   now,
	}

	data, err := json.Marshal(user)
	if err != nil {
		t.Fatalf("failed to marshal user: %v", err)
	}

	var parsed map[string]interface{}
	if err := json.Unmarshal(data, &parsed); err != nil {
		t.Fatalf("failed to unmarshal JSON: %v", err)
	}

	// Verify password hash is never exposed
	if _, exists := parsed["passwordHash"]; exists {
		t.Fatal("passwordHash must never be exposed in JSON")
	}
	if _, exists := parsed["PasswordHash"]; exists {
		t.Fatal("PasswordHash must never be exposed in JSON")
	}

	// Verify profile fields exist
	if parsed["avatarUrl"] != "https://example.com/avatar.png" {
		t.Fatalf("expected avatarUrl, got %v", parsed["avatarUrl"])
	}
	if parsed["bio"] != "Software architect and designer" {
		t.Fatalf("expected bio, got %v", parsed["bio"])
	}

	prefs, ok := parsed["preferences"].(map[string]interface{})
	if !ok {
		t.Fatalf("expected preferences object, got %T", parsed["preferences"])
	}
	if prefs["theme"] != "system" {
		t.Fatalf("expected default theme 'system', got %v", prefs["theme"])
	}
}

func TestProfileStatsModel(t *testing.T) {
	stats := &models.UserStats{
		OwnedProjectsCount:  3,
		SharedProjectsCount: 2,
		TotalProjectsCount:  5,
		CreatedBoardsCount:  8,
		TotalBoardsCount:    14,
		AccountCreatedAt:    time.Now().UTC(),
	}

	data, err := json.Marshal(stats)
	if err != nil {
		t.Fatalf("failed to marshal stats: %v", err)
	}

	var parsed map[string]interface{}
	if err := json.Unmarshal(data, &parsed); err != nil {
		t.Fatalf("failed to unmarshal stats: %v", err)
	}

	if parsed["ownedProjectsCount"] != float64(3) {
		t.Fatalf("expected ownedProjectsCount = 3, got %v", parsed["ownedProjectsCount"])
	}
	if parsed["totalBoardsCount"] != float64(14) {
		t.Fatalf("expected totalBoardsCount = 14, got %v", parsed["totalBoardsCount"])
	}
}

func TestProfileTokenGenerationOnEmailUpdate(t *testing.T) {
	tokenSvc := auth.NewTokenService("test-secret-key-123", time.Hour)
	userID := uuid.New()
	newEmail := "updated@example.com"

	token, expiresAt, err := tokenSvc.GenerateToken(userID, newEmail)
	if err != nil {
		t.Fatalf("failed to generate token: %v", err)
	}
	if token == "" {
		t.Fatal("token should not be empty")
	}
	if expiresAt.Before(time.Now()) {
		t.Fatal("expiration should be in the future")
	}

	claims, err := tokenSvc.ValidateToken(token)
	if err != nil {
		t.Fatalf("token validation failed: %v", err)
	}
	if claims.Email != newEmail {
		t.Fatalf("expected token claim email %s, got %s", newEmail, claims.Email)
	}
}

func TestDirectoryCreationInProfileHandler(t *testing.T) {
	tempDir := t.TempDir()
	uploadsDir := tempDir + "/test_uploads"

	_ = NewProfileHandler(nil, nil, 4, uploadsDir)

	avatarsPath := uploadsDir + "/avatars"
	if _, err := os.Stat(avatarsPath); os.IsNotExist(err) {
		t.Fatalf("expected directory %s to be created automatically", avatarsPath)
	}
}
