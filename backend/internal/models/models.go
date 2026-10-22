package models

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// DefaultPreferences provides standard initial settings for new accounts
var DefaultPreferences = json.RawMessage(`{"theme":"system","grid":true,"snapToGrid":false,"emailNotifications":true}`)

// User represents an authenticated account
type User struct {
	ID           uuid.UUID       `json:"id"`
	Name         string          `json:"name"`
	Email        string          `json:"email"`
	PasswordHash string          `json:"-"` // Never expose in JSON
	DisplayName  string          `json:"displayName"`
	AvatarURL    string          `json:"avatarUrl"`
	Bio          string          `json:"bio"`
	Preferences  json.RawMessage `json:"preferences"`
	CreatedAt    time.Time       `json:"createdAt"`
	UpdatedAt    time.Time       `json:"updatedAt"`
}

// UserStats represents aggregated user metrics for the profile dashboard
type UserStats struct {
	OwnedProjectsCount  int       `json:"ownedProjectsCount"`
	SharedProjectsCount int       `json:"sharedProjectsCount"`
	TotalProjectsCount  int       `json:"totalProjectsCount"`
	CreatedBoardsCount  int       `json:"createdBoardsCount"`
	TotalBoardsCount    int       `json:"totalBoardsCount"`
	AccountCreatedAt    time.Time `json:"accountCreatedAt"`
}

// RecentBoard represents a board accessed or accessible by the user, with project context
type RecentBoard struct {
	ID          uuid.UUID   `json:"id"`
	ProjectID   uuid.UUID   `json:"projectId"`
	ProjectName string      `json:"projectName"`
	Name        string      `json:"name"`
	Revision    int64       `json:"revision"`
	Role        ProjectRole `json:"role"`
	CreatedBy   *uuid.UUID  `json:"createdBy,omitempty"`
	CreatedAt   time.Time   `json:"createdAt"`
	UpdatedAt   time.Time   `json:"updatedAt"`
}

// UserProfileResponse bundles user information along with optional stats
type UserProfileResponse struct {
	User  *User      `json:"user"`
	Stats *UserStats `json:"stats,omitempty"`
}

// Project represents a workspace container
type Project struct {
	ID        uuid.UUID `json:"id"`
	OwnerID   uuid.UUID `json:"ownerId"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`
}

// Board represents a drawing workspace
type Board struct {
	ID        uuid.UUID       `json:"id"`
	ProjectID uuid.UUID       `json:"projectId"`
	Name      string          `json:"name"`
	Content   json.RawMessage `json:"content"`
	Viewport  json.RawMessage `json:"viewport"`
	Revision  int64           `json:"revision"`
	CreatedBy *uuid.UUID      `json:"createdBy,omitempty"`
	CreatedAt time.Time       `json:"createdAt"`
	UpdatedAt time.Time       `json:"updatedAt"`
}

// BoardSummary is a lightweight board representation (without heavy content JSON)
type BoardSummary struct {
	ID        uuid.UUID  `json:"id"`
	ProjectID uuid.UUID  `json:"projectId"`
	Name      string     `json:"name"`
	Revision  int64      `json:"revision"`
	CreatedBy *uuid.UUID `json:"createdBy,omitempty"`
	CreatedAt time.Time  `json:"createdAt"`
	UpdatedAt time.Time  `json:"updatedAt"`
}

// ProjectDetails includes project metadata, user role, and member/board counts
type ProjectDetails struct {
	Project
	UserRole    ProjectRole `json:"userRole"`
	MemberCount int         `json:"memberCount"`
	BoardCount  int         `json:"boardCount"`
}

// ProjectRole defines the role of a member
type ProjectRole string

const (
	RoleOwner  ProjectRole = "owner"
	RoleEditor ProjectRole = "editor"
	RoleViewer ProjectRole = "viewer"
)

// ProjectMember represents membership in a project
type ProjectMember struct {
	ProjectID uuid.UUID   `json:"projectId"`
	UserID    uuid.UUID   `json:"userId"`
	Role      ProjectRole `json:"role"`
	JoinedAt  time.Time   `json:"joinedAt"`

	// Populated for member listings
	User *User `json:"user,omitempty"`
}

// Invitation represents an email invite to a project
type Invitation struct {
	ID         uuid.UUID   `json:"id"`
	ProjectID  uuid.UUID   `json:"projectId"`
	Email      string      `json:"email"`
	TokenHash  string      `json:"-"` // Never expose token hash
	Role       ProjectRole `json:"role"`
	ExpiresAt  time.Time   `json:"expiresAt"`
	AcceptedAt *time.Time  `json:"acceptedAt,omitempty"`
	CreatedBy  *uuid.UUID  `json:"createdBy,omitempty"`
	CreatedAt  time.Time   `json:"createdAt"`

	// Dynamic attribute indicating whether the invited user exists in the system
	UserExists bool `json:"userExists"`
}
