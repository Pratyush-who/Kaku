package handlers

import (
	"net/http"
	"strings"

	"github.com/Pratyush-who/Kaku/backend/internal/auth"
	"github.com/Pratyush-who/Kaku/backend/internal/httputil"
	"github.com/Pratyush-who/Kaku/backend/internal/middleware"
	"github.com/Pratyush-who/Kaku/backend/internal/repository"
)

type InvitationHandler struct {
	repo *repository.PostgresRepository
}

func NewInvitationHandler(repo *repository.PostgresRepository) *InvitationHandler {
	return &InvitationHandler{repo: repo}
}

// HandleInvitation routes /api/v1/invitations/{token} and /api/v1/invitations/{token}/accept
func (h *InvitationHandler) HandleInvitation(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/api/v1/invitations/")
	parts := strings.Split(strings.Trim(path, "/"), "/")
	if len(parts) == 0 || parts[0] == "" {
		httputil.Error(w, http.StatusBadRequest, "Invalid invitation token")
		return
	}

	rawToken := parts[0]
	tokenHash := auth.HashToken(rawToken)

	// GET /api/v1/invitations/{token} - inspect invitation
	if len(parts) == 1 {
		if r.Method != http.MethodGet {
			httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
			return
		}

		inv, err := h.repo.GetInvitationByTokenHash(r.Context(), tokenHash)
		if err != nil {
			httputil.Error(w, http.StatusNotFound, "Invitation not found or invalid")
			return
		}

		httputil.JSON(w, http.StatusOK, inv)
		return
	}

	// POST /api/v1/invitations/{token}/accept - accepts the invitation
	if len(parts) == 2 && parts[1] == "accept" {
		if r.Method != http.MethodPost {
			httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
			return
		}

		userID, ok := middleware.GetUserIDFromContext(r.Context())
		if !ok {
			httputil.Error(w, http.StatusUnauthorized, "Authentication required to accept an invitation")
			return
		}
		userEmail, _ := middleware.GetEmailFromContext(r.Context())

		if err := h.repo.AcceptInvitation(r.Context(), tokenHash, userID, userEmail); err != nil {
			httputil.Error(w, http.StatusBadRequest, err.Error())
			return
		}

		httputil.JSON(w, http.StatusOK, map[string]string{"message": "Invitation accepted successfully"})
		return
	}

	httputil.Error(w, http.StatusNotFound, "Endpoint not found")
}
