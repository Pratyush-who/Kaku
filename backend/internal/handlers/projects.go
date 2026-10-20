package handlers

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/Pratyush-who/Kaku/backend/internal/auth"
	"github.com/Pratyush-who/Kaku/backend/internal/httputil"
	"github.com/Pratyush-who/Kaku/backend/internal/middleware"
	"github.com/Pratyush-who/Kaku/backend/internal/models"
	"github.com/Pratyush-who/Kaku/backend/internal/repository"
)

type ProjectHandler struct {
	repo *repository.PostgresRepository
}

func NewProjectHandler(repo *repository.PostgresRepository) *ProjectHandler {
	return &ProjectHandler{repo: repo}
}

type CreateProjectRequest struct {
	Name string `json:"name"`
}

func (h *ProjectHandler) HandleProjects(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		httputil.Error(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	switch r.Method {
	case http.MethodGet:
		projects, err := h.repo.ListUserProjects(r.Context(), userID)
		if err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to list projects")
			return
		}
		if projects == nil {
			projects = []models.ProjectDetails{}
		}
		httputil.JSON(w, http.StatusOK, projects)

	case http.MethodPost:
		var req CreateProjectRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			httputil.Error(w, http.StatusBadRequest, "Invalid request body")
			return
		}
		req.Name = strings.TrimSpace(req.Name)
		if req.Name == "" {
			httputil.Error(w, http.StatusBadRequest, "Project name is required")
			return
		}

		project := &models.Project{
			ID:      uuid.New(),
			OwnerID: userID,
			Name:    req.Name,
		}

		if err := h.repo.CreateProject(r.Context(), project); err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to create project")
			return
		}

		httputil.JSON(w, http.StatusCreated, project)

	default:
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
	}
}

func (h *ProjectHandler) HandleProjectByID(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		httputil.Error(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	// URL format: /api/v1/projects/{projectId} or with sub-resources
	path := strings.TrimPrefix(r.URL.Path, "/api/v1/projects/")
	trimmed := strings.Trim(path, "/")
	if trimmed == "" {
		h.HandleProjects(w, r)
		return
	}
	parts := strings.Split(trimmed, "/")

	projectID, err := uuid.Parse(parts[0])
	if err != nil {
		httputil.Error(w, http.StatusBadRequest, "Invalid project UUID format")
		return
	}

	// Verify project access
	role, err := h.repo.GetUserProjectRole(r.Context(), projectID, userID)
	if err != nil {
		if errors.Is(err, repository.ErrForbidden) {
			httputil.Error(w, http.StatusForbidden, "You do not have access to this project")
			return
		}
		httputil.Error(w, http.StatusInternalServerError, "Database error")
		return
	}

	// Route sub-resources:
	// /api/v1/projects/{id}
	// /api/v1/projects/{id}/members
	// /api/v1/projects/{id}/members/{userId}
	// /api/v1/projects/{id}/invitations
	// /api/v1/projects/{id}/boards
	if len(parts) == 1 {
		switch r.Method {
		case http.MethodGet:
			project, err := h.repo.GetProjectDetails(r.Context(), projectID, userID)
			if err != nil {
				httputil.Error(w, http.StatusNotFound, "Project not found")
				return
			}
			httputil.JSON(w, http.StatusOK, project)

		case http.MethodPatch:
			if role != models.RoleOwner && role != models.RoleEditor {
				httputil.Error(w, http.StatusForbidden, "Only editors and owners can edit project metadata")
				return
			}
			var req CreateProjectRequest
			if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
				httputil.Error(w, http.StatusBadRequest, "Invalid request body")
				return
			}
			req.Name = strings.TrimSpace(req.Name)
			if req.Name == "" {
				httputil.Error(w, http.StatusBadRequest, "Project name cannot be empty")
				return
			}
			if err := h.repo.UpdateProjectName(r.Context(), projectID, req.Name); err != nil {
				httputil.Error(w, http.StatusInternalServerError, "Failed to update project")
				return
			}
			project, _ := h.repo.GetProjectByID(r.Context(), projectID)
			httputil.JSON(w, http.StatusOK, project)

		case http.MethodDelete:
			if role != models.RoleOwner {
				httputil.Error(w, http.StatusForbidden, "Only project owners can delete a project")
				return
			}
			if err := h.repo.DeleteProject(r.Context(), projectID); err != nil {
				httputil.Error(w, http.StatusInternalServerError, "Failed to delete project")
				return
			}
			httputil.JSON(w, http.StatusOK, map[string]string{"message": "Project deleted successfully"})

		default:
			httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		}
		return
	}

	subResource := parts[1]
	switch subResource {
	case "members":
		h.handleMembers(w, r, projectID, role, parts[2:])
	case "invitations":
		h.handleInvitations(w, r, projectID, userID, role)
	case "boards":
		h.handleProjectBoards(w, r, projectID, userID, role)
	default:
		httputil.Error(w, http.StatusNotFound, "Endpoint not found")
	}
}

func (h *ProjectHandler) handleMembers(w http.ResponseWriter, r *http.Request, projectID uuid.UUID, role models.ProjectRole, remaining []string) {
	if len(remaining) == 0 {
		if r.Method == http.MethodGet {
			members, err := h.repo.ListProjectMembers(r.Context(), projectID)
			if err != nil {
				httputil.Error(w, http.StatusInternalServerError, "Failed to list members")
				return
			}
			httputil.JSON(w, http.StatusOK, members)
			return
		}
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	// DELETE /api/v1/projects/{projectId}/members/{userId}
	if len(remaining) == 1 && r.Method == http.MethodDelete {
		if role != models.RoleOwner {
			httputil.Error(w, http.StatusForbidden, "Only project owners can remove members")
			return
		}
		targetUserID, err := uuid.Parse(remaining[0])
		if err != nil {
			httputil.Error(w, http.StatusBadRequest, "Invalid user ID")
			return
		}
		if err := h.repo.RemoveProjectMember(r.Context(), projectID, targetUserID); err != nil {
			httputil.Error(w, http.StatusBadRequest, err.Error())
			return
		}
		httputil.JSON(w, http.StatusOK, map[string]string{"message": "Member removed successfully"})
		return
	}

	httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
}

type CreateInvitationRequest struct {
	Email string             `json:"email"`
	Role  models.ProjectRole `json:"role"`
}

type InvitationResponse struct {
	Invitation *models.Invitation `json:"invitation"`
	RawToken   string             `json:"token,omitempty"` // Returned only upon creation
}

func (h *ProjectHandler) handleInvitations(w http.ResponseWriter, r *http.Request, projectID, userID uuid.UUID, role models.ProjectRole) {
	switch r.Method {
	case http.MethodGet:
		invs, err := h.repo.ListProjectInvitations(r.Context(), projectID)
		if err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to fetch invitations")
			return
		}
		if invs == nil {
			invs = []models.Invitation{}
		}
		httputil.JSON(w, http.StatusOK, invs)

	case http.MethodPost:
		if role != models.RoleOwner && role != models.RoleEditor {
			httputil.Error(w, http.StatusForbidden, "Only owners and editors can invite collaborators")
			return
		}

		var req CreateInvitationRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			httputil.Error(w, http.StatusBadRequest, "Invalid request body")
			return
		}
		req.Email = strings.TrimSpace(strings.ToLower(req.Email))
		if req.Email == "" {
			httputil.Error(w, http.StatusBadRequest, "Email is required")
			return
		}
		if req.Role == "" {
			req.Role = models.RoleEditor
		}
		if req.Role != models.RoleViewer && req.Role != models.RoleEditor {
			httputil.Error(w, http.StatusBadRequest, "Role must be 'viewer' or 'editor'")
			return
		}

		// Generate cryptographically random token
		tokenBytes := make([]byte, 32)
		if _, err := rand.Read(tokenBytes); err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to generate token")
			return
		}
		rawToken := hex.EncodeToString(tokenBytes)
		tokenHash := auth.HashToken(rawToken)

		// Check if user already exists in DB
		userExists, _ := h.repo.UserExistsByEmail(r.Context(), req.Email)

		invitation := &models.Invitation{
			ID:         uuid.New(),
			ProjectID:  projectID,
			Email:      req.Email,
			TokenHash:  tokenHash,
			Role:       req.Role,
			ExpiresAt:  time.Now().Add(7 * 24 * time.Hour), // 7 days expiry
			CreatedBy:  &userID,
			UserExists: userExists,
		}

		if err := h.repo.CreateInvitation(r.Context(), invitation); err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to create invitation")
			return
		}

		httputil.JSON(w, http.StatusCreated, InvitationResponse{
			Invitation: invitation,
			RawToken:   rawToken,
		})

	default:
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
	}
}

type CreateBoardRequest struct {
	Name     string          `json:"name"`
	Content  json.RawMessage `json:"content,omitempty"`
	Viewport json.RawMessage `json:"viewport,omitempty"`
}

func (h *ProjectHandler) handleProjectBoards(w http.ResponseWriter, r *http.Request, projectID, userID uuid.UUID, role models.ProjectRole) {
	switch r.Method {
	case http.MethodGet:
		boards, err := h.repo.ListProjectBoardsSummary(r.Context(), projectID)
		if err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to list boards")
			return
		}
		if boards == nil {
			boards = []models.BoardSummary{}
		}
		httputil.JSON(w, http.StatusOK, boards)

	case http.MethodPost:
		if role != models.RoleOwner && role != models.RoleEditor {
			httputil.Error(w, http.StatusForbidden, "Only owners and editors can create boards")
			return
		}

		var req CreateBoardRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			httputil.Error(w, http.StatusBadRequest, "Invalid request body")
			return
		}
		req.Name = strings.TrimSpace(req.Name)
		if req.Name == "" {
			httputil.Error(w, http.StatusBadRequest, "Board name is required")
			return
		}

		board := &models.Board{
			ID:        uuid.New(),
			ProjectID: projectID,
			Name:      req.Name,
			Content:   req.Content,
			Viewport:  req.Viewport,
			Revision:  0,
			CreatedBy: &userID,
		}

		if err := h.repo.CreateBoard(r.Context(), board); err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to create board")
			return
		}

		httputil.JSON(w, http.StatusCreated, board)

	default:
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
	}
}
