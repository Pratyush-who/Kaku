package handlers

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/google/uuid"

	"github.com/Pratyush-who/Kaku/backend/internal/auth"
	"github.com/Pratyush-who/Kaku/backend/internal/httputil"
	"github.com/Pratyush-who/Kaku/backend/internal/middleware"
	"github.com/Pratyush-who/Kaku/backend/internal/models"
	"github.com/Pratyush-who/Kaku/backend/internal/repository"
)

type AuthHandler struct {
	repo         *repository.PostgresRepository
	tokenService *auth.TokenService
	bcryptCost   int
}

func NewAuthHandler(repo *repository.PostgresRepository, tokenService *auth.TokenService, bcryptCost int) *AuthHandler {
	return &AuthHandler{
		repo:         repo,
		tokenService: tokenService,
		bcryptCost:   bcryptCost,
	}
}

type RegisterRequest struct {
	Name        string `json:"name"`
	Email       string `json:"email"`
	Password    string `json:"password"`
	DisplayName string `json:"displayName"`
}

type AuthResponse struct {
	User  *models.User `json:"user"`
	Token string       `json:"token"`
}

func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	var req RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httputil.Error(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	req.Email = strings.TrimSpace(strings.ToLower(req.Email))
	req.Name = strings.TrimSpace(req.Name)
	req.DisplayName = strings.TrimSpace(req.DisplayName)

	if req.Email == "" || req.Password == "" || req.Name == "" {
		httputil.Error(w, http.StatusBadRequest, "Name, email, and password are required")
		return
	}
	if len(req.Password) < 8 {
		httputil.Error(w, http.StatusBadRequest, "Password must be at least 8 characters")
		return
	}
	if req.DisplayName == "" {
		req.DisplayName = req.Name
	}

	// Check if email already registered
	exists, err := h.repo.UserExistsByEmail(r.Context(), req.Email)
	if err != nil {
		httputil.Error(w, http.StatusInternalServerError, "Database error")
		return
	}
	if exists {
		httputil.Error(w, http.StatusConflict, "Email is already registered")
		return
	}

	// Encrypt password using bcrypt
	hashedPass, err := auth.HashPassword(req.Password, h.bcryptCost)
	if err != nil {
		httputil.Error(w, http.StatusInternalServerError, "Failed to hash password")
		return
	}

	user := &models.User{
		ID:           uuid.New(),
		Name:         req.Name,
		Email:        req.Email,
		PasswordHash: hashedPass,
		DisplayName:  req.DisplayName,
	}

	if err := h.repo.CreateUser(r.Context(), user); err != nil {
		httputil.Error(w, http.StatusInternalServerError, "Failed to create user")
		return
	}

	token, _, err := h.tokenService.GenerateToken(user.ID, user.Email)
	if err != nil {
		httputil.Error(w, http.StatusInternalServerError, "Failed to issue session token")
		return
	}

	httputil.JSON(w, http.StatusCreated, AuthResponse{
		User:  user,
		Token: token,
	})
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httputil.Error(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	req.Email = strings.TrimSpace(strings.ToLower(req.Email))
	if req.Email == "" || req.Password == "" {
		httputil.Error(w, http.StatusBadRequest, "Email and password are required")
		return
	}

	user, err := h.repo.GetUserByEmail(r.Context(), req.Email)
	if err != nil {
		httputil.Error(w, http.StatusUnauthorized, "Invalid email or password")
		return
	}

	if !auth.CheckPassword(req.Password, user.PasswordHash) {
		httputil.Error(w, http.StatusUnauthorized, "Invalid email or password")
		return
	}

	token, _, err := h.tokenService.GenerateToken(user.ID, user.Email)
	if err != nil {
		httputil.Error(w, http.StatusInternalServerError, "Failed to issue session token")
		return
	}

	httputil.JSON(w, http.StatusOK, AuthResponse{
		User:  user,
		Token: token,
	})
}

func (h *AuthHandler) Me(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		httputil.Error(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	switch r.Method {
	case http.MethodGet:
		user, err := h.repo.GetUserByID(r.Context(), userID)
		if err != nil {
			httputil.Error(w, http.StatusNotFound, "User not found")
			return
		}
		httputil.JSON(w, http.StatusOK, user)

	case http.MethodPatch, http.MethodPut:
		var req struct {
			Name        string `json:"name"`
			DisplayName string `json:"displayName"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			httputil.Error(w, http.StatusBadRequest, "Invalid request body")
			return
		}

		user, err := h.repo.GetUserByID(r.Context(), userID)
		if err != nil {
			httputil.Error(w, http.StatusNotFound, "User not found")
			return
		}

		name := strings.TrimSpace(req.Name)
		if name == "" {
			name = user.Name
		}
		displayName := strings.TrimSpace(req.DisplayName)
		if displayName == "" {
			displayName = user.DisplayName
		}

		updatedUser, err := h.repo.UpdateUserProfile(r.Context(), userID, name, displayName)
		if err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to update profile")
			return
		}
		httputil.JSON(w, http.StatusOK, updatedUser)

	default:
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
	}
}

type ChangePasswordRequest struct {
	CurrentPassword string `json:"currentPassword"`
	NewPassword     string `json:"newPassword"`
}

func (h *AuthHandler) ChangePassword(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		httputil.Error(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req ChangePasswordRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httputil.Error(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if req.CurrentPassword == "" || req.NewPassword == "" {
		httputil.Error(w, http.StatusBadRequest, "Current password and new password are required")
		return
	}

	if len(req.NewPassword) < 8 {
		httputil.Error(w, http.StatusBadRequest, "New password must be at least 8 characters")
		return
	}

	user, err := h.repo.GetUserByID(r.Context(), userID)
	if err != nil {
		httputil.Error(w, http.StatusNotFound, "User not found")
		return
	}

	if !auth.CheckPassword(req.CurrentPassword, user.PasswordHash) {
		httputil.Error(w, http.StatusUnauthorized, "Current password is incorrect")
		return
	}

	newHash, err := auth.HashPassword(req.NewPassword, h.bcryptCost)
	if err != nil {
		httputil.Error(w, http.StatusInternalServerError, "Failed to encrypt new password")
		return
	}

	if err := h.repo.UpdateUserPassword(r.Context(), userID, newHash); err != nil {
		httputil.Error(w, http.StatusInternalServerError, "Failed to update password")
		return
	}

	httputil.JSON(w, http.StatusOK, map[string]string{"message": "Password updated successfully"})
}

