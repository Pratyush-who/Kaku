package auth

import (
	"testing"
	"time"

	"github.com/google/uuid"
)

func TestPasswordHashing(t *testing.T) {
	password := "superSecret123!"
	cost := 10

	hash, err := HashPassword(password, cost)
	if err != nil {
		t.Fatalf("unexpected error hashing password: %v", err)
	}

	if hash == password {
		t.Fatal("hash should not equal plain text password")
	}

	if !CheckPassword(password, hash) {
		t.Fatal("password verification failed for matching password")
	}

	if CheckPassword("wrongPassword", hash) {
		t.Fatal("password verification passed for invalid password")
	}
}

func TestTokenGenerationAndValidation(t *testing.T) {
	secret := "test-secret-key-12345"
	svc := NewTokenService(secret, 1*time.Hour)

	userID := uuid.New()
	email := "test@example.com"

	token, expiresAt, err := svc.GenerateToken(userID, email)
	if err != nil {
		t.Fatalf("unexpected error generating token: %v", err)
	}
	if token == "" {
		t.Fatal("expected non-empty token string")
	}
	if expiresAt.Before(time.Now()) {
		t.Fatal("expiration date should be in the future")
	}

	// Validate valid token
	claims, err := svc.ValidateToken(token)
	if err != nil {
		t.Fatalf("validation failed: %v", err)
	}
	if claims.UserID != userID {
		t.Fatalf("expected userID %v, got %v", userID, claims.UserID)
	}
	if claims.Email != email {
		t.Fatalf("expected email %s, got %s", email, claims.Email)
	}

	// Validate with wrong secret
	diffSvc := NewTokenService("different-secret", 1*time.Hour)
	if _, err := diffSvc.ValidateToken(token); err == nil {
		t.Fatal("expected validation error with different secret")
	}
}

func TestTokenHashing(t *testing.T) {
	token := "sample-raw-invitation-token"
	hash1 := HashToken(token)
	hash2 := HashToken(token)

	if hash1 != hash2 {
		t.Fatal("hashes of identical token must match")
	}
	if len(hash1) != 64 { // SHA-256 hex string is 64 characters
		t.Fatalf("expected hex length 64, got %d", len(hash1))
	}
}
