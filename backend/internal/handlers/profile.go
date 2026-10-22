package handlers

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/mail"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/Pratyush-who/Kaku/backend/internal/auth"
	"github.com/Pratyush-who/Kaku/backend/internal/httputil"
	"github.com/Pratyush-who/Kaku/backend/internal/middleware"
	"github.com/Pratyush-who/Kaku/backend/internal/models"
	"github.com/Pratyush-who/Kaku/backend/internal/repository"
)

type ProfileHandler struct {
	repo         *repository.PostgresRepository
	tokenService *auth.TokenService
	bcryptCost   int
	uploadsDir   string
}

func NewProfileHandler(repo *repository.PostgresRepository, tokenService *auth.TokenService, bcryptCost int, uploadsDir string) *ProfileHandler {
	if uploadsDir == "" {
		uploadsDir = "./uploads"
	}
	_ = os.MkdirAll(filepath.Join(uploadsDir, "avatars"), 0755)

	return &ProfileHandler{
		repo:         repo,
		tokenService: tokenService,
		bcryptCost:   bcryptCost,
		uploadsDir:   uploadsDir,
	}
}

// UpdateProfileRequest defines permissible fields when modifying profile information
type UpdateProfileRequest struct {
	Name        *string          `json:"name"`
	DisplayName *string          `json:"displayName"`
	AvatarURL   *string          `json:"avatarUrl"`
	Bio         *string          `json:"bio"`
	Preferences json.RawMessage `json:"preferences"`
}

// DeleteAccountRequest requires password confirmation before irreversible deletion
type DeleteAccountRequest struct {
	Password string `json:"password"`
}

// UpdateEmailRequest allows modifying user email with password verification
type UpdateEmailRequest struct {
	NewEmail string `json:"newEmail"`
	Password string `json:"password"`
}

// UpdateAvatarRequest allows updating avatar URL directly
type UpdateAvatarRequest struct {
	AvatarURL string `json:"avatarUrl"`
}

// HandleMe handles /api/v1/me and /api/v1/profile
func (h *ProfileHandler) HandleMe(w http.ResponseWriter, r *http.Request) {
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

		// Optional ?include=stats parameter
		if strings.EqualFold(r.URL.Query().Get("include"), "stats") {
			stats, err := h.repo.GetUserStats(r.Context(), userID)
			if err != nil {
				httputil.Error(w, http.StatusInternalServerError, "Failed to load profile statistics")
				return
			}
			httputil.JSON(w, http.StatusOK, models.UserProfileResponse{
				User:  user,
				Stats: stats,
			})
			return
		}

		httputil.JSON(w, http.StatusOK, user)

	case http.MethodPatch, http.MethodPut:
		var req UpdateProfileRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			httputil.Error(w, http.StatusBadRequest, "Invalid request body")
			return
		}

		user, err := h.repo.GetUserByID(r.Context(), userID)
		if err != nil {
			httputil.Error(w, http.StatusNotFound, "User not found")
			return
		}

		name := user.Name
		if req.Name != nil {
			trimmed := strings.TrimSpace(*req.Name)
			if trimmed == "" {
				httputil.Error(w, http.StatusBadRequest, "Name cannot be empty")
				return
			}
			if len(trimmed) > 100 {
				httputil.Error(w, http.StatusBadRequest, "Name cannot exceed 100 characters")
				return
			}
			name = trimmed
		}

		displayName := user.DisplayName
		if req.DisplayName != nil {
			trimmed := strings.TrimSpace(*req.DisplayName)
			if trimmed == "" {
				trimmed = name
			}
			if len(trimmed) > 100 {
				httputil.Error(w, http.StatusBadRequest, "Display name cannot exceed 100 characters")
				return
			}
			displayName = trimmed
		}

		avatarURL := user.AvatarURL
		if req.AvatarURL != nil {
			trimmed := strings.TrimSpace(*req.AvatarURL)
			if len(trimmed) > 2048 {
				httputil.Error(w, http.StatusBadRequest, "Avatar URL cannot exceed 2048 characters")
				return
			}
			avatarURL = trimmed
		}

		bio := user.Bio
		if req.Bio != nil {
			trimmed := strings.TrimSpace(*req.Bio)
			if len(trimmed) > 500 {
				httputil.Error(w, http.StatusBadRequest, "Bio cannot exceed 500 characters")
				return
			}
			bio = trimmed
		}

		updatedUser, err := h.repo.UpdateUserProfile(r.Context(), userID, name, displayName, avatarURL, bio)
		if err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to update profile")
			return
		}

		// Update preferences if provided
		if len(req.Preferences) > 0 {
			var testMap map[string]interface{}
			if err := json.Unmarshal(req.Preferences, &testMap); err != nil {
				httputil.Error(w, http.StatusBadRequest, "Preferences must be a valid JSON object")
				return
			}

			updatedUser, err = h.repo.UpdateUserPreferences(r.Context(), userID, req.Preferences)
			if err != nil {
				httputil.Error(w, http.StatusInternalServerError, "Failed to update preferences")
				return
			}
		}

		httputil.JSON(w, http.StatusOK, updatedUser)

	case http.MethodDelete:
		// Delete account permanently
		var req DeleteAccountRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			httputil.Error(w, http.StatusBadRequest, "Password is required to delete account")
			return
		}

		if req.Password == "" {
			httputil.Error(w, http.StatusBadRequest, "Password is required to confirm account deletion")
			return
		}

		user, err := h.repo.GetUserByID(r.Context(), userID)
		if err != nil {
			httputil.Error(w, http.StatusNotFound, "User not found")
			return
		}

		if !auth.CheckPassword(req.Password, user.PasswordHash) {
			httputil.Error(w, http.StatusUnauthorized, "Incorrect password")
			return
		}

		if err := h.repo.DeleteUser(r.Context(), userID); err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to delete account")
			return
		}

		httputil.JSON(w, http.StatusOK, map[string]string{
			"message": "Account successfully deleted",
		})

	default:
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
	}
}

// HandleMeSubpaths handles sub-routes under /api/v1/me/ and /api/v1/profile/
func (h *ProfileHandler) HandleMeSubpaths(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		httputil.Error(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	// Determine subpath: check whether prefix is /api/v1/me/ or /api/v1/profile/
	path := r.URL.Path
	var subpath string
	if strings.HasPrefix(path, "/api/v1/me/") {
		subpath = strings.TrimPrefix(path, "/api/v1/me/")
	} else if strings.HasPrefix(path, "/api/v1/profile/") {
		subpath = strings.TrimPrefix(path, "/api/v1/profile/")
	} else {
		httputil.Error(w, http.StatusNotFound, "Endpoint not found")
		return
	}

	subpath = strings.Trim(subpath, "/")
	if subpath == "" {
		h.HandleMe(w, r)
		return
	}

	switch subpath {
	case "stats":
		h.handleStats(w, r, userID)
	case "recent-boards", "activity":
		h.handleRecentBoards(w, r, userID)
	case "preferences":
		h.handlePreferences(w, r, userID)
	case "avatar":
		h.handleAvatar(w, r, userID)
	case "password":
		h.handlePassword(w, r, userID)
	case "email":
		h.handleEmail(w, r, userID)
	default:
		httputil.Error(w, http.StatusNotFound, "Endpoint not found")
	}
}

// handleStats returns workspace metrics for the profile dashboard
func (h *ProfileHandler) handleStats(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
	if r.Method != http.MethodGet {
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	stats, err := h.repo.GetUserStats(r.Context(), userID)
	if err != nil {
		httputil.Error(w, http.StatusInternalServerError, "Failed to fetch user statistics")
		return
	}

	httputil.JSON(w, http.StatusOK, stats)
}

// handleRecentBoards returns recent boards accessed/created across all projects
func (h *ProfileHandler) handleRecentBoards(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
	if r.Method != http.MethodGet {
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	limit := 10
	offset := 0

	if lStr := r.URL.Query().Get("limit"); lStr != "" {
		if l, err := strconv.Atoi(lStr); err == nil && l > 0 {
			limit = l
		}
	}
	if oStr := r.URL.Query().Get("offset"); oStr != "" {
		if o, err := strconv.Atoi(oStr); err == nil && o >= 0 {
			offset = o
		}
	}

	boards, total, err := h.repo.ListUserRecentBoards(r.Context(), userID, limit, offset)
	if err != nil {
		httputil.Error(w, http.StatusInternalServerError, "Failed to fetch recent boards")
		return
	}

	httputil.JSON(w, http.StatusOK, map[string]interface{}{
		"boards": boards,
		"total":  total,
		"limit":  limit,
		"offset": offset,
	})
}

// handlePreferences gets or updates user preferences
func (h *ProfileHandler) handlePreferences(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
	switch r.Method {
	case http.MethodGet:
		user, err := h.repo.GetUserByID(r.Context(), userID)
		if err != nil {
			httputil.Error(w, http.StatusNotFound, "User not found")
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write(user.Preferences)

	case http.MethodPatch, http.MethodPut:
		body, err := io.ReadAll(io.LimitReader(r.Body, 64*1024)) // 64KB max preferences
		if err != nil || len(body) == 0 {
			httputil.Error(w, http.StatusBadRequest, "Invalid request body")
			return
		}

		var testMap map[string]interface{}
		if err := json.Unmarshal(body, &testMap); err != nil {
			httputil.Error(w, http.StatusBadRequest, "Preferences must be a valid JSON object")
			return
		}

		user, err := h.repo.UpdateUserPreferences(r.Context(), userID, body)
		if err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to update preferences")
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write(user.Preferences)

	default:
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
	}
}

// handleAvatar manages profile avatar uploads, url updates, and avatar removal
func (h *ProfileHandler) handleAvatar(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
	switch r.Method {
	case http.MethodPost, http.MethodPut:
		contentType := r.Header.Get("Content-Type")

		// 1. Multipart file upload
		if strings.HasPrefix(contentType, "multipart/form-data") {
			// 5 MB max memory
			if err := r.ParseMultipartForm(5 << 20); err != nil {
				httputil.Error(w, http.StatusBadRequest, "File too large or invalid multipart form (max 5MB)")
				return
			}

			file, header, err := r.FormFile("avatar")
			if err != nil {
				file, header, err = r.FormFile("file")
			}
			if err != nil {
				httputil.Error(w, http.StatusBadRequest, "Missing avatar file in form-data ('avatar' or 'file' key)")
				return
			}
			defer file.Close()

			// Read first 512 bytes to sniff content type
			buf := make([]byte, 512)
			n, err := file.Read(buf)
			if err != nil && err != io.EOF {
				httputil.Error(w, http.StatusBadRequest, "Failed to read uploaded file")
				return
			}
			fileType := http.DetectContentType(buf[:n])

			allowedExtensions := map[string]string{
				"image/jpeg":    ".jpg",
				"image/png":     ".png",
				"image/gif":     ".gif",
				"image/webp":    ".webp",
				"image/svg+xml": ".svg",
			}

			ext, allowed := allowedExtensions[fileType]
			if !allowed {
				// Check filename extension as fallback for SVG
				origExt := strings.ToLower(filepath.Ext(header.Filename))
				if origExt == ".svg" && strings.Contains(fileType, "text/") {
					ext = ".svg"
				} else {
					httputil.Error(w, http.StatusBadRequest, "Unsupported image type. Allowed: JPEG, PNG, GIF, WEBP, SVG")
					return
				}
			}

			// Rewind file reader
			if _, err := file.Seek(0, io.SeekStart); err != nil {
				httputil.Error(w, http.StatusInternalServerError, "Failed to process file")
				return
			}

			filename := fmt.Sprintf("avatar_%s_%d%s", userID.String(), time.Now().UnixNano(), ext)
			destPath := filepath.Join(h.uploadsDir, "avatars", filename)

			destFile, err := os.Create(destPath)
			if err != nil {
				httputil.Error(w, http.StatusInternalServerError, "Failed to save avatar")
				return
			}
			defer destFile.Close()

			if _, err := io.Copy(destFile, file); err != nil {
				httputil.Error(w, http.StatusInternalServerError, "Failed to write avatar file")
				return
			}

			avatarURL := "/uploads/avatars/" + filename
			user, err := h.repo.UpdateUserAvatar(r.Context(), userID, avatarURL)
			if err != nil {
				httputil.Error(w, http.StatusInternalServerError, "Failed to record avatar")
				return
			}

			httputil.JSON(w, http.StatusOK, map[string]interface{}{
				"message":   "Avatar uploaded successfully",
				"avatarUrl": avatarURL,
				"user":      user,
			})
			return
		}

		// 2. JSON avatar URL update
		var req UpdateAvatarRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			httputil.Error(w, http.StatusBadRequest, "Invalid request body")
			return
		}

		trimmed := strings.TrimSpace(req.AvatarURL)
		if len(trimmed) > 2048 {
			httputil.Error(w, http.StatusBadRequest, "Avatar URL cannot exceed 2048 characters")
			return
		}

		user, err := h.repo.UpdateUserAvatar(r.Context(), userID, trimmed)
		if err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to update avatar")
			return
		}

		httputil.JSON(w, http.StatusOK, map[string]interface{}{
			"message":   "Avatar updated successfully",
			"avatarUrl": trimmed,
			"user":      user,
		})

	case http.MethodDelete:
		user, err := h.repo.UpdateUserAvatar(r.Context(), userID, "")
		if err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to remove avatar")
			return
		}

		httputil.JSON(w, http.StatusOK, map[string]interface{}{
			"message":   "Avatar removed successfully",
			"avatarUrl": "",
			"user":      user,
		})

	default:
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
	}
}

// handlePassword handles password changes
func (h *ProfileHandler) handlePassword(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
	if r.Method != http.MethodPost {
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
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

	if req.CurrentPassword == req.NewPassword {
		httputil.Error(w, http.StatusBadRequest, "New password must be different from current password")
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

	httputil.JSON(w, http.StatusOK, map[string]string{
		"message": "Password updated successfully",
	})
}

// handleEmail handles changing account email with password verification
func (h *ProfileHandler) handleEmail(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
	if r.Method != http.MethodPost {
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	var req UpdateEmailRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httputil.Error(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	newEmail := strings.TrimSpace(strings.ToLower(req.NewEmail))
	if newEmail == "" || req.Password == "" {
		httputil.Error(w, http.StatusBadRequest, "New email and current password are required")
		return
	}

	// Validate email format
	parsedAddr, err := mail.ParseAddress(newEmail)
	if err != nil || parsedAddr.Address != newEmail || !strings.Contains(newEmail, ".") {
		httputil.Error(w, http.StatusBadRequest, "Invalid email address format")
		return
	}

	user, err := h.repo.GetUserByID(r.Context(), userID)
	if err != nil {
		httputil.Error(w, http.StatusNotFound, "User not found")
		return
	}

	if strings.EqualFold(user.Email, newEmail) {
		httputil.Error(w, http.StatusBadRequest, "New email must be different from current email")
		return
	}

	if !auth.CheckPassword(req.Password, user.PasswordHash) {
		httputil.Error(w, http.StatusUnauthorized, "Incorrect password")
		return
	}

	// Check if new email is taken
	exists, err := h.repo.UserExistsByEmail(r.Context(), newEmail)
	if err != nil {
		httputil.Error(w, http.StatusInternalServerError, "Database error")
		return
	}
	if exists {
		httputil.Error(w, http.StatusConflict, "Email is already in use by another account")
		return
	}

	updatedUser, err := h.repo.UpdateUserEmail(r.Context(), userID, newEmail)
	if err != nil {
		httputil.Error(w, http.StatusInternalServerError, "Failed to update email")
		return
	}

	// Issue a fresh token for the updated email
	token, _, err := h.tokenService.GenerateToken(updatedUser.ID, updatedUser.Email)
	if err != nil {
		httputil.Error(w, http.StatusInternalServerError, "Failed to reissue authentication token")
		return
	}

	httputil.JSON(w, http.StatusOK, map[string]interface{}{
		"message": "Email updated successfully",
		"user":    updatedUser,
		"token":   token,
	})
}
