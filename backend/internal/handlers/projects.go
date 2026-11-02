package handlers

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
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

type ProjectHandler struct {
	repo *repository.PostgresRepository
}

func NewProjectHandler(repo *repository.PostgresRepository) *ProjectHandler {
	return &ProjectHandler{repo: repo}
}

type CreateProjectRequest struct {
	Name        string `json:"name"`
	Description string `json:"description,omitempty"`
}

type UpdateProjectRequest struct {
	Name        string `json:"name,omitempty"`
	Description string `json:"description,omitempty"`
}

type ProjectShareSettingsRequest struct {
	IsPublic        *bool              `json:"isPublic,omitempty"`
	PublicRole      models.ProjectRole `json:"publicRole,omitempty"`
	RegenerateToken bool               `json:"regenerateToken,omitempty"`
}

type AddMemberRequest struct {
	UserID *uuid.UUID         `json:"userId,omitempty"`
	Email  string             `json:"email,omitempty"`
	Role   models.ProjectRole `json:"role"`
}

type UpdateMemberRoleRequest struct {
	Role models.ProjectRole `json:"role"`
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
			ID:          uuid.New(),
			OwnerID:     userID,
			Name:        req.Name,
			Description: strings.TrimSpace(req.Description),
			IsPublic:    false,
			PublicRole:  models.RoleViewer,
			ShareToken:  uuid.New().String(),
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
			var req UpdateProjectRequest
			if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
				httputil.Error(w, http.StatusBadRequest, "Invalid request body")
				return
			}
			name := strings.TrimSpace(req.Name)
			desc := req.Description
			if desc == "" && req.Name != "" {
				desc = "__KEEP__"
			}

			if err := h.repo.UpdateProjectMetadata(r.Context(), projectID, name, desc); err != nil {
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
	case "collaborators":
		h.handleCollaborators(w, r, projectID, userID, role)
	case "share":
		h.handleProjectShare(w, r, projectID, userID, role)
	case "invitations":
		h.handleInvitations(w, r, projectID, userID, role)
	case "boards":
		h.handleProjectBoards(w, r, projectID, userID, role, parts[2:])
	default:
		httputil.Error(w, http.StatusNotFound, "Endpoint not found")
	}
}

func (h *ProjectHandler) handleMembers(w http.ResponseWriter, r *http.Request, projectID uuid.UUID, role models.ProjectRole, remaining []string) {
	if len(remaining) == 0 {
		switch r.Method {
		case http.MethodGet:
			members, err := h.repo.ListProjectMembers(r.Context(), projectID)
			if err != nil {
				httputil.Error(w, http.StatusInternalServerError, "Failed to list members")
				return
			}
			httputil.JSON(w, http.StatusOK, members)

		case http.MethodPost:
			if role != models.RoleOwner && role != models.RoleEditor {
				httputil.Error(w, http.StatusForbidden, "Only owners and editors can add members directly")
				return
			}
			var req AddMemberRequest
			if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
				httputil.Error(w, http.StatusBadRequest, "Invalid request body")
				return
			}
			if req.Role != models.RoleViewer && req.Role != models.RoleEditor {
				req.Role = models.RoleEditor
			}

			var targetUserID uuid.UUID
			if req.UserID != nil && *req.UserID != uuid.Nil {
				targetUserID = *req.UserID
			} else if strings.TrimSpace(req.Email) != "" {
				user, err := h.repo.GetUserByEmail(r.Context(), strings.TrimSpace(req.Email))
				if err != nil {
					httputil.Error(w, http.StatusNotFound, "User not found with that email. Use invitation instead.")
					return
				}
				targetUserID = user.ID
			} else {
				httputil.Error(w, http.StatusBadRequest, "User ID or email is required")
				return
			}

			if err := h.repo.AddOrUpdateProjectMember(r.Context(), projectID, targetUserID, req.Role); err != nil {
				httputil.Error(w, http.StatusBadRequest, err.Error())
				return
			}
			members, _ := h.repo.ListProjectMembers(r.Context(), projectID)
			httputil.JSON(w, http.StatusOK, map[string]interface{}{
				"message": "Member added successfully",
				"members": members,
			})

		default:
			httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		}
		return
	}

	// Subpath: /api/v1/projects/{projectId}/members/{userId}
	if len(remaining) == 1 {
		targetUserID, err := uuid.Parse(remaining[0])
		if err != nil {
			httputil.Error(w, http.StatusBadRequest, "Invalid user ID")
			return
		}

		switch r.Method {
		case http.MethodPatch, http.MethodPut:
			if role != models.RoleOwner && role != models.RoleEditor {
				httputil.Error(w, http.StatusForbidden, "Only owners and editors can update member roles")
				return
			}
			var req UpdateMemberRoleRequest
			if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
				httputil.Error(w, http.StatusBadRequest, "Invalid request body")
				return
			}
			if req.Role != models.RoleViewer && req.Role != models.RoleEditor {
				httputil.Error(w, http.StatusBadRequest, "Role must be 'viewer' or 'editor'")
				return
			}
			if err := h.repo.UpdateProjectMemberRole(r.Context(), projectID, targetUserID, req.Role); err != nil {
				httputil.Error(w, http.StatusBadRequest, err.Error())
				return
			}
			httputil.JSON(w, http.StatusOK, map[string]string{
				"message": "Member role updated successfully",
			})

		case http.MethodDelete:
			if role != models.RoleOwner {
				httputil.Error(w, http.StatusForbidden, "Only project owners can remove members")
				return
			}
			if err := h.repo.RemoveProjectMember(r.Context(), projectID, targetUserID); err != nil {
				httputil.Error(w, http.StatusBadRequest, err.Error())
				return
			}
			httputil.JSON(w, http.StatusOK, map[string]string{"message": "Member removed successfully"})

		default:
			httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		}
		return
	}

	httputil.Error(w, http.StatusNotFound, "Endpoint not found")
}

// handleCollaborators provides a Google Drive style unified collaborator management endpoint
// GET: overview of owner, members, pending invites, and share link settings
// POST: add or invite collaborator by email or user ID
func (h *ProjectHandler) handleCollaborators(w http.ResponseWriter, r *http.Request, projectID, userID uuid.UUID, role models.ProjectRole) {
	switch r.Method {
	case http.MethodGet:
		project, err := h.repo.GetProjectByID(r.Context(), projectID)
		if err != nil {
			httputil.Error(w, http.StatusNotFound, "Project not found")
			return
		}

		members, err := h.repo.ListProjectMembers(r.Context(), projectID)
		if err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to load members")
			return
		}

		invitations, err := h.repo.ListProjectInvitations(r.Context(), projectID)
		if err != nil {
			invitations = []models.Invitation{}
		}

		ownerUser, _ := h.repo.GetUserByID(r.Context(), project.OwnerID)
		var ownerPublic *models.UserPublic
		if ownerUser != nil {
			ownerPublic = &models.UserPublic{
				ID:          ownerUser.ID,
				Name:        ownerUser.Name,
				DisplayName: ownerUser.DisplayName,
				AvatarURL:   ownerUser.AvatarURL,
			}
		}

		shareResp := models.ProjectShareSettingsResponse{
			ProjectID:   project.ID,
			Name:        project.Name,
			ShareToken:  project.ShareToken,
			ShareURL:    fmt.Sprintf("/shared/projects/%s", project.ShareToken),
			IsPublic:    project.IsPublic,
			PublicRole:  project.PublicRole,
			MemberCount: len(members),
		}

		httputil.JSON(w, http.StatusOK, models.ProjectCollaboratorsOverview{
			ProjectID:   project.ID,
			Owner:       ownerPublic,
			Members:     members,
			Invitations: invitations,
			Share:       shareResp,
		})

	case http.MethodPost:
		if role != models.RoleOwner && role != models.RoleEditor {
			httputil.Error(w, http.StatusForbidden, "Only owners and editors can add collaborators")
			return
		}

		var req models.AddCollaboratorRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			httputil.Error(w, http.StatusBadRequest, "Invalid request body")
			return
		}

		req.Email = strings.TrimSpace(strings.ToLower(req.Email))
		if req.Role != models.RoleViewer && req.Role != models.RoleEditor {
			req.Role = models.RoleEditor
		}

		// Check if target user exists in database
		var targetUser *models.User
		var err error
		if req.UserID != nil && *req.UserID != uuid.Nil {
			targetUser, err = h.repo.GetUserByID(r.Context(), *req.UserID)
		} else if req.Email != "" {
			targetUser, err = h.repo.GetUserByEmail(r.Context(), req.Email)
		} else {
			httputil.Error(w, http.StatusBadRequest, "Email or user ID is required")
			return
		}

		// 1. If user already exists in Kaku, add them directly as a member!
		if err == nil && targetUser != nil {
			if err := h.repo.AddOrUpdateProjectMember(r.Context(), projectID, targetUser.ID, req.Role); err != nil {
				httputil.Error(w, http.StatusBadRequest, err.Error())
				return
			}
			httputil.JSON(w, http.StatusOK, models.AddCollaboratorResponse{
				Type:    "member_added",
				Message: fmt.Sprintf("Added %s directly to the project as %s", targetUser.DisplayName, req.Role),
				User:    targetUser,
				Role:    req.Role,
			})
			return
		}

		// 2. If user is not yet registered in Kaku, create an email invitation
		if req.Email == "" {
			httputil.Error(w, http.StatusBadRequest, "Valid email required for user invitation")
			return
		}

		tokenBytes := make([]byte, 32)
		if _, err := rand.Read(tokenBytes); err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to generate token")
			return
		}
		rawToken := hex.EncodeToString(tokenBytes)
		tokenHash := auth.HashToken(rawToken)

		invitation := &models.Invitation{
			ID:         uuid.New(),
			ProjectID:  projectID,
			Email:      req.Email,
			TokenHash:  tokenHash,
			Role:       req.Role,
			ExpiresAt:  time.Now().Add(7 * 24 * time.Hour),
			CreatedBy:  &userID,
			UserExists: false,
		}

		if err := h.repo.CreateInvitation(r.Context(), invitation); err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to create invitation")
			return
		}

		httputil.JSON(w, http.StatusCreated, models.AddCollaboratorResponse{
			Type:       "invitation_created",
			Message:    fmt.Sprintf("Invitation link created for %s", req.Email),
			Invitation: invitation,
			RawToken:   rawToken,
			ShareURL:   fmt.Sprintf("/invitations/%s", rawToken),
			Role:       req.Role,
		})

	default:
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
	}
}

// handleProjectShare manages general access / public share links for the project
func (h *ProjectHandler) handleProjectShare(w http.ResponseWriter, r *http.Request, projectID, userID uuid.UUID, role models.ProjectRole) {
	project, err := h.repo.GetProjectByID(r.Context(), projectID)
	if err != nil {
		httputil.Error(w, http.StatusNotFound, "Project not found")
		return
	}

	members, _ := h.repo.ListProjectMembers(r.Context(), projectID)

	switch r.Method {
	case http.MethodGet:
		httputil.JSON(w, http.StatusOK, models.ProjectShareSettingsResponse{
			ProjectID:   project.ID,
			Name:        project.Name,
			ShareToken:  project.ShareToken,
			ShareURL:    fmt.Sprintf("/shared/projects/%s", project.ShareToken),
			IsPublic:    project.IsPublic,
			PublicRole:  project.PublicRole,
			MemberCount: len(members),
		})

	case http.MethodPost:
		if role != models.RoleOwner && role != models.RoleEditor {
			httputil.Error(w, http.StatusForbidden, "Only owners and editors can configure project sharing")
			return
		}

		var req ProjectShareSettingsRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			httputil.Error(w, http.StatusBadRequest, "Invalid request body")
			return
		}

		isPublic := project.IsPublic
		if req.IsPublic != nil {
			isPublic = *req.IsPublic
		}

		publicRole := project.PublicRole
		if req.PublicRole == models.RoleViewer || req.PublicRole == models.RoleEditor {
			publicRole = req.PublicRole
		}

		newShareToken := ""
		if req.RegenerateToken || project.ShareToken == "" {
			newShareToken = uuid.New().String()
		}

		if err := h.repo.UpdateProjectShareSettings(r.Context(), project.ID, isPublic, publicRole, newShareToken); err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to update share settings")
			return
		}

		updated, err := h.repo.GetProjectByID(r.Context(), project.ID)
		if err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to load updated project")
			return
		}

		httputil.JSON(w, http.StatusOK, models.ProjectShareSettingsResponse{
			ProjectID:   updated.ID,
			Name:        updated.Name,
			ShareToken:  updated.ShareToken,
			ShareURL:    fmt.Sprintf("/shared/projects/%s", updated.ShareToken),
			IsPublic:    updated.IsPublic,
			PublicRole:  updated.PublicRole,
			MemberCount: len(members),
		})

	default:
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
	}
}

// HandleSearchUsers handles GET /api/v1/users/search?q={query}&projectId={optionalProjectId}&limit={limit}
// Allows Google Drive style autocomplete when typing an email or collaborator name
func (h *ProjectHandler) HandleSearchUsers(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		httputil.Error(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	query := strings.TrimSpace(r.URL.Query().Get("q"))
	if query == "" {
		httputil.JSON(w, http.StatusOK, []models.UserSearchResult{})
		return
	}

	limit := 20
	if l := r.URL.Query().Get("limit"); l != "" {
		if val, err := strconv.Atoi(l); err == nil && val > 0 {
			limit = val
		}
	}

	var projectIDPtr *uuid.UUID
	if projStr := r.URL.Query().Get("projectId"); projStr != "" {
		if pID, err := uuid.Parse(projStr); err == nil {
			projectIDPtr = &pID
		}
	}

	results, err := h.repo.SearchUsers(r.Context(), query, userID, projectIDPtr, limit)
	if err != nil {
		httputil.Error(w, http.StatusInternalServerError, "Failed to search users")
		return
	}

	httputil.JSON(w, http.StatusOK, results)
}

// HandleGlobalSearch handles GET /api/v1/search?q={query}&limit={limit}
// Searches projects and boards matching query keywords or collaborator emails
func (h *ProjectHandler) HandleGlobalSearch(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		httputil.Error(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	query := strings.TrimSpace(r.URL.Query().Get("q"))
	if query == "" {
		httputil.JSON(w, http.StatusOK, models.GlobalSearchResult{
			Projects: []models.ProjectDetails{},
			Boards:   []models.RecentBoard{},
		})
		return
	}

	limit := 20
	if l := r.URL.Query().Get("limit"); l != "" {
		if val, err := strconv.Atoi(l); err == nil && val > 0 {
			limit = val
		}
	}

	results, err := h.repo.SearchProjectsAndBoards(r.Context(), userID, query, limit)
	if err != nil {
		httputil.Error(w, http.StatusInternalServerError, "Search failed")
		return
	}

	httputil.JSON(w, http.StatusOK, results)
}

// HandleSharedProject handles public project view and joining:
// GET /api/v1/shared/projects/{shareToken}
// POST /api/v1/shared/projects/{shareToken}/join
func (h *ProjectHandler) HandleSharedProject(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/api/v1/shared/projects/")
	parts := strings.Split(strings.Trim(path, "/"), "/")
	if len(parts) == 0 || parts[0] == "" {
		httputil.Error(w, http.StatusBadRequest, "Share token is required")
		return
	}

	shareToken := parts[0]

	// 1. Inspect public project: GET /api/v1/shared/projects/{shareToken}
	if len(parts) == 1 && r.Method == http.MethodGet {
		project, err := h.repo.GetProjectByShareToken(r.Context(), shareToken)
		if err != nil {
			httputil.Error(w, http.StatusNotFound, "Shared project not found or link has expired")
			return
		}

		owner, _ := h.repo.GetUserByID(r.Context(), project.OwnerID)
		var ownerPublic *models.UserPublic
		if owner != nil {
			ownerPublic = &models.UserPublic{
				ID:          owner.ID,
				Name:        owner.Name,
				DisplayName: owner.DisplayName,
				AvatarURL:   owner.AvatarURL,
			}
		}

		boards, err := h.repo.ListProjectBoardsSummary(r.Context(), project.ID)
		if err != nil {
			boards = []models.BoardSummary{}
		}

		members, _ := h.repo.ListProjectMembers(r.Context(), project.ID)

		httputil.JSON(w, http.StatusOK, models.PublicProjectResponse{
			Project:     project,
			Owner:       ownerPublic,
			PublicRole:  project.PublicRole,
			Boards:      boards,
			MemberCount: len(members),
		})
		return
	}

	// 2. Join public project: POST /api/v1/shared/projects/{shareToken}/join
	if len(parts) == 2 && parts[1] == "join" {
		if r.Method != http.MethodPost {
			httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
			return
		}

		userID, ok := middleware.GetUserIDFromContext(r.Context())
		if !ok {
			httputil.Error(w, http.StatusUnauthorized, "Authentication required to join project")
			return
		}

		project, assignedRole, err := h.repo.JoinProjectByShareToken(r.Context(), shareToken, userID)
		if err != nil {
			httputil.Error(w, http.StatusBadRequest, err.Error())
			return
		}

		httputil.JSON(w, http.StatusOK, map[string]interface{}{
			"message": "Successfully joined project",
			"project": project,
			"role":    assignedRole,
		})
		return
	}

	httputil.Error(w, http.StatusNotFound, "Endpoint not found")
}

type CreateInvitationRequest struct {
	Email string             `json:"email"`
	Role  models.ProjectRole `json:"role"`
}

type InvitationResponse struct {
	Invitation *models.Invitation `json:"invitation"`
	RawToken   string             `json:"token,omitempty"`
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

		tokenBytes := make([]byte, 32)
		if _, err := rand.Read(tokenBytes); err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to generate token")
			return
		}
		rawToken := hex.EncodeToString(tokenBytes)
		tokenHash := auth.HashToken(rawToken)

		userExists, _ := h.repo.UserExistsByEmail(r.Context(), req.Email)

		invitation := &models.Invitation{
			ID:         uuid.New(),
			ProjectID:  projectID,
			Email:      req.Email,
			TokenHash:  tokenHash,
			Role:       req.Role,
			ExpiresAt:  time.Now().Add(7 * 24 * time.Hour),
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
	Name        string          `json:"name"`
	Description string          `json:"description,omitempty"`
	Thumbnail   string          `json:"thumbnail,omitempty"`
	Content     json.RawMessage `json:"content,omitempty"`
	Viewport    json.RawMessage `json:"viewport,omitempty"`
}

func (h *ProjectHandler) handleProjectBoards(w http.ResponseWriter, r *http.Request, projectID, userID uuid.UUID, role models.ProjectRole, remaining []string) {
	if len(remaining) > 0 && remaining[0] == "trash" {
		if r.Method != http.MethodGet {
			httputil.Error(w, http.StatusMethodNotAllowed, "Method not allowed")
			return
		}
		trashed, err := h.repo.ListProjectTrashedBoards(r.Context(), projectID)
		if err != nil {
			httputil.Error(w, http.StatusInternalServerError, "Failed to list trashed boards")
			return
		}
		if trashed == nil {
			trashed = []models.BoardSummary{}
		}
		httputil.JSON(w, http.StatusOK, trashed)
		return
	}

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
			ID:          uuid.New(),
			ProjectID:   projectID,
			Name:        req.Name,
			Description: strings.TrimSpace(req.Description),
			Thumbnail:   strings.TrimSpace(req.Thumbnail),
			Content:     req.Content,
			Viewport:    req.Viewport,
			Revision:    0,
			CreatedBy:   &userID,
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
