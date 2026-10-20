package handlers

import (
	"encoding/json"
	"errors"
	"net/http"
	"strings"

	"github.com/google/uuid"

	"github.com/Pratyush-who/Kaku/backend/internal/httputil"
	"github.com/Pratyush-who/Kaku/backend/internal/middleware"
	"github.com/Pratyush-who/Kaku/backend/internal/models"
	"github.com/Pratyush-who/Kaku/backend/internal/repository"
)

type BoardHandler struct {
	repo *repository.PostgresRepository
}

func NewBoardHandler(repo *repository.PostgresRepository) *BoardHandler {
	return &BoardHandler{repo: repo}
}

type UpdateBoardRequest struct {
	Name string `json:"name"`
}

type SaveBoardContentRequest struct {
	ExpectedRevision int64           `json:"expectedRevision"`
	Content          json.RawMessage `json:"content"`
	Viewport         json.RawMessage `json:"viewport,omitempty"`
}

type SaveBoardContentResponse struct {
	BoardID  uuid.UUID `json:"boardId"`
	Revision int64     `json:"revision"`
	Message  string    `json:"message"`
}

func (h *BoardHandler) HandleBoardByID(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		httputil.Error(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	// URL format: /api/v1/boards/{boardId} or /api/v1/boards/{boardId}/content
	path := strings.TrimPrefix(r.URL.Path, "/api/v1/boards/")
	path = strings.TrimPrefix(path, "/api/v1/boards")
	trimmed := strings.Trim(path, "/")
	if trimmed == "" {
		httputil.Error(w, http.StatusBadRequest, "Board ID is required")
		return
	}
	parts := strings.Split(trimmed, "/")

	boardID, err := uuid.Parse(parts[0])
	if err != nil {
		httputil.Error(w, http.StatusBadRequest, "Invalid board UUID format")
		return
	}

	board, err := h.repo.GetBoardByID(r.Context(), boardID)
	if err != nil {
		httputil.Error(w, http.StatusNotFound, "Board not found")
		return
	}

	// Verify user permissions on parent project
	role, err := h.repo.GetUserProjectRole(r.Context(), board.ProjectID, userID)
	if err != nil {
		if errors.Is(err, repository.ErrForbidden) {
			httputil.Error(w, http.StatusForbidden, "You do not have access to this board")
			return
		}
		httputil.Error(w, http.StatusInternalServerError, "Database error")
		return
	}

	if len(parts) == 1 {
		switch r.Method {
		case http.MethodGet:
			httputil.JSON(w, http.StatusOK, board)

		case http.MethodPatch:
			if role != models.RoleOwner && role != models.RoleEditor {
				httputil.Error(w, http.StatusForbidden, "Insufficient permissions to update board")
				return
			}
			var req UpdateBoardRequest
			if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
				httputil.Error(w, http.StatusBadRequest, "Invalid request body")
				return
			}
			req.Name = strings.TrimSpace(req.Name)
			if req.Name == "" {
				httputil.Error(w, http.StatusBadRequest, "Board name cannot be empty")
				return
			}
			if err := h.repo.UpdateBoardMetadata(r.Context(), boardID, req.Name); err != nil {
				httputil.Error(w, http.StatusInternalServerError, "Failed to update board")
				return
			}
			updated, _ := h.repo.GetBoardByID(r.Context(), boardID)
			httputil.JSON(w, http.StatusOK, updated)

		case http.MethodDelete:
			if role != models.RoleOwner && role != models.RoleEditor {
				httputil.Error(w, http.StatusForbidden, "Insufficient permissions to delete board")
				return
			}
			if err := h.repo.DeleteBoard(r.Context(), boardID); err != nil {
				httputil.Error(w, http.StatusInternalServerError, "Failed to delete board")
				return
			}
			httputil.JSON(w, http.StatusOK, map[string]string{"message": "Board deleted successfully"})

		default:
			httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		}
		return
	}

	// /api/v1/boards/{boardId}/content
	if len(parts) == 2 && parts[1] == "content" {
		if r.Method != http.MethodPut {
			httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
			return
		}

		if role != models.RoleOwner && role != models.RoleEditor {
			httputil.Error(w, http.StatusForbidden, "Viewers cannot modify board content")
			return
		}

		var req SaveBoardContentRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			httputil.Error(w, http.StatusBadRequest, "Invalid request body")
			return
		}

		if len(req.Content) == 0 {
			httputil.Error(w, http.StatusBadRequest, "Content payload cannot be empty")
			return
		}

		newRev, err := h.repo.UpdateBoardContent(r.Context(), boardID, req.Content, req.Viewport, req.ExpectedRevision)
		if err != nil {
			if errors.Is(err, repository.ErrConflict) {
				httputil.Error(w, http.StatusConflict, "Conflict: board revision has changed on the server. Please reload or merge.")
				return
			}
			httputil.Error(w, http.StatusInternalServerError, "Failed to persist board content")
			return
		}

		httputil.JSON(w, http.StatusOK, SaveBoardContentResponse{
			BoardID:  boardID,
			Revision: newRev,
			Message:  "Board content updated successfully",
		})
		return
	}

	// /api/v1/boards/{boardId}/duplicate
	if len(parts) == 2 && parts[1] == "duplicate" {
		if r.Method != http.MethodPost {
			httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
			return
		}

		if role != models.RoleOwner && role != models.RoleEditor {
			httputil.Error(w, http.StatusForbidden, "Only owners and editors can duplicate boards")
			return
		}

		var req struct {
			Name string `json:"name"`
		}
		_ = json.NewDecoder(r.Body).Decode(&req)

		clonedBoard, err := h.repo.DuplicateBoard(r.Context(), boardID, userID, strings.TrimSpace(req.Name))
		if err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to duplicate board")
			return
		}

		httputil.JSON(w, http.StatusCreated, clonedBoard)
		return
	}

	httputil.Error(w, http.StatusNotFound, "Endpoint not found")
}
