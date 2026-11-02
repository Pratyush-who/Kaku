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
	ID          uuid.UUID   `json:"id"`
	OwnerID     uuid.UUID   `json:"ownerId"`
	Name        string      `json:"name"`
	Description string      `json:"description"`
	IsPublic    bool        `json:"isPublic"`
	PublicRole  ProjectRole `json:"publicRole"`
	ShareToken  string      `json:"shareToken,omitempty"`
	CreatedAt   time.Time   `json:"createdAt"`
	UpdatedAt   time.Time   `json:"updatedAt"`
}

// Board represents a drawing workspace
type Board struct {
	ID           uuid.UUID       `json:"id"`
	ProjectID    uuid.UUID       `json:"projectId"`
	Name         string          `json:"name"`
	Description  string          `json:"description"`
	Thumbnail    string          `json:"thumbnail"`
	Content      json.RawMessage `json:"content"`
	Viewport     json.RawMessage `json:"viewport"`
	Revision     int64           `json:"revision"`
	IsPublic     bool            `json:"isPublic"`
	PublicRole   ProjectRole     `json:"publicRole"`
	ShareToken   string          `json:"shareToken,omitempty"`
	HasPassword  bool            `json:"hasPassword"`
	PasswordHash string          `json:"-"`
	IsTrashed    bool            `json:"isTrashed"`
	TrashedAt    *time.Time      `json:"trashedAt,omitempty"`
	CreatedBy    *uuid.UUID      `json:"createdBy,omitempty"`
	CreatedAt    time.Time       `json:"createdAt"`
	UpdatedAt    time.Time       `json:"updatedAt"`
}

// BoardSummary is a lightweight board representation (without heavy content JSON)
type BoardSummary struct {
	ID          uuid.UUID   `json:"id"`
	ProjectID   uuid.UUID   `json:"projectId"`
	Name        string      `json:"name"`
	Description string      `json:"description"`
	Thumbnail   string      `json:"thumbnail"`
	Revision    int64       `json:"revision"`
	IsPublic    bool        `json:"isPublic"`
	PublicRole  ProjectRole `json:"publicRole"`
	ShareToken  string      `json:"shareToken,omitempty"`
	HasPassword bool        `json:"hasPassword"`
	IsTrashed   bool        `json:"isTrashed"`
	TrashedAt   *time.Time  `json:"trashedAt,omitempty"`
	CreatedBy   *uuid.UUID  `json:"createdBy,omitempty"`
	CreatedAt   time.Time   `json:"createdAt"`
	UpdatedAt   time.Time   `json:"updatedAt"`
}

// BoardElement represents a discrete shape, drawing, arrow, text, or image on the canvas
type BoardElement struct {
	ID                 string          `json:"id"`
	BoardID            uuid.UUID       `json:"boardId"`
	Type               string          `json:"type"` // rectangle, ellipse, diamond, arrow, line, freedraw, text, image, frame
	X                  float64         `json:"x"`
	Y                  float64         `json:"y"`
	Width              float64         `json:"width"`
	Height             float64         `json:"height"`
	Angle              float64         `json:"angle"`
	StrokeColor        string          `json:"strokeColor"`
	BackgroundColor    string          `json:"backgroundColor"`
	FillStyle          string          `json:"fillStyle"`
	StrokeWidth        float64         `json:"strokeWidth"`
	StrokeStyle        string          `json:"strokeStyle"`
	Roughness          float64         `json:"roughness"`
	Opacity            float64         `json:"opacity"`
	Text               string          `json:"text"`
	FontSize           float64         `json:"fontSize"`
	FontFamily         string          `json:"fontFamily"`
	TextAlign          string          `json:"textAlign"`
	Points             json.RawMessage `json:"points"`
	Properties         json.RawMessage `json:"properties"`
	ZIndex             int64           `json:"zIndex"`
	Version            int64           `json:"version"`
	IsDeleted          bool            `json:"isDeleted"`
	CreatedBy          *uuid.UUID      `json:"createdBy,omitempty"`
	CreatedByName      string          `json:"createdByName,omitempty"`
	LastModifiedBy     *uuid.UUID      `json:"lastModifiedBy,omitempty"`
	LastModifiedByName string          `json:"lastModifiedByName,omitempty"`
	CreatedAt          time.Time       `json:"createdAt"`
	UpdatedAt          time.Time       `json:"updatedAt"`
}

// BoardVersion represents a historical snapshot of the canvas
type BoardVersion struct {
	ID            uuid.UUID       `json:"id"`
	BoardID       uuid.UUID       `json:"boardId"`
	VersionNumber int             `json:"versionNumber"`
	Title         string          `json:"title"`
	Description   string          `json:"description"`
	Content       json.RawMessage `json:"content"`
	Viewport      json.RawMessage `json:"viewport"`
	CreatedBy     *uuid.UUID      `json:"createdBy,omitempty"`
	CreatedByName string          `json:"createdByName,omitempty"`
	CreatedAt     time.Time       `json:"createdAt"`
}

// BoardActivity logs events on the board (e.g. joined, drew, restored)
type BoardActivity struct {
	ID        uuid.UUID       `json:"id"`
	BoardID   uuid.UUID       `json:"boardId"`
	UserID    *uuid.UUID      `json:"userId,omitempty"`
	UserName  string          `json:"userName,omitempty"`
	Action    string          `json:"action"`
	Details   json.RawMessage `json:"details"`
	CreatedAt time.Time       `json:"createdAt"`
}

// CollaboratorSummary encapsulates "who who drew" - contributor element metrics
type CollaboratorSummary struct {
	UserID        uuid.UUID `json:"userId"`
	Name          string    `json:"name"`
	DisplayName   string    `json:"displayName"`
	AvatarURL     string    `json:"avatarUrl"`
	ElementsDrawn int       `json:"elementsDrawn"`
	LastDrewAt    time.Time `json:"lastDrewAt"`
}

// ActiveCollaborator represents a live collaborator currently connected to the canvas
type ActiveCollaborator struct {
	UserID           string    `json:"userId"`
	Name             string    `json:"name"`
	DisplayName      string    `json:"displayName"`
	AvatarURL        string    `json:"avatarUrl"`
	Role             string    `json:"role"`
	Color            string    `json:"color"`
	CursorX          float64   `json:"cursorX"`
	CursorY          float64   `json:"cursorY"`
	IsDrawing        bool      `json:"isDrawing"`
	DrawingTool      string    `json:"drawingTool"`
	CurrentElementID string    `json:"currentElementId,omitempty"`
	ConnectedAt      time.Time `json:"connectedAt"`
	LastActiveAt     time.Time `json:"lastActiveAt"`
}

// BoardCollaboratorsResponse bundles live active users and historical contributors
type BoardCollaboratorsResponse struct {
	ActiveUsers  []ActiveCollaborator  `json:"activeUsers"`
	Contributors []CollaboratorSummary `json:"contributors"`
}


// ProjectDetails includes project metadata, user role, and member/board counts
type ProjectDetails struct {
	Project
	UserRole    ProjectRole `json:"userRole"`
	MemberCount int         `json:"memberCount"`
	BoardCount  int         `json:"boardCount"`
	ShareURL    string      `json:"shareUrl,omitempty"`
}

// UserPublic is a safe public representation of a user (no email or password)
type UserPublic struct {
	ID          uuid.UUID `json:"id"`
	Name        string    `json:"name"`
	DisplayName string    `json:"displayName"`
	AvatarURL   string    `json:"avatarUrl"`
}

// UserSearchResult represents a user found via email/name autocomplete search
type UserSearchResult struct {
	ID          uuid.UUID   `json:"id"`
	Name        string      `json:"name"`
	Email       string      `json:"email"`
	DisplayName string      `json:"displayName"`
	AvatarURL   string      `json:"avatarUrl"`
	IsMember    bool        `json:"isMember,omitempty"`
	Role        ProjectRole `json:"role,omitempty"`
}

// ProjectShareSettingsResponse bundles link-sharing settings for a project
type ProjectShareSettingsResponse struct {
	ProjectID   uuid.UUID   `json:"projectId"`
	Name        string      `json:"name"`
	ShareToken  string      `json:"shareToken"`
	ShareURL    string      `json:"shareUrl"`
	IsPublic    bool        `json:"isPublic"`
	PublicRole  ProjectRole `json:"publicRole"`
	MemberCount int         `json:"memberCount"`
}

// PublicProjectResponse bundles project info for public shared link view
type PublicProjectResponse struct {
	Project     *Project       `json:"project"`
	Owner       *UserPublic    `json:"owner"`
	PublicRole  ProjectRole    `json:"publicRole"`
	Boards      []BoardSummary `json:"boards"`
	MemberCount int            `json:"memberCount"`
}

// AddCollaboratorRequest allows adding a collaborator by email or userId
type AddCollaboratorRequest struct {
	Email  string      `json:"email"`
	UserID *uuid.UUID  `json:"userId,omitempty"`
	Role   ProjectRole `json:"role"`
}

// AddCollaboratorResponse describes whether member was directly added or invitation dispatched
type AddCollaboratorResponse struct {
	Type       string        `json:"type"` // "member_added", "member_updated", "invitation_created"
	Message    string        `json:"message"`
	User       *User         `json:"user,omitempty"`
	Invitation *Invitation   `json:"invitation,omitempty"`
	RawToken   string        `json:"token,omitempty"`
	ShareURL   string        `json:"shareUrl,omitempty"`
	Role       ProjectRole   `json:"role"`
}

// ProjectCollaboratorsOverview bundles members and pending invitations for the share dialog
type ProjectCollaboratorsOverview struct {
	ProjectID   uuid.UUID       `json:"projectId"`
	Owner       *UserPublic     `json:"owner"`
	Members     []ProjectMember `json:"members"`
	Invitations []Invitation    `json:"invitations"`
	Share       ProjectShareSettingsResponse `json:"share"`
}

// GlobalSearchResult encapsulates matching projects and boards from keyword/email search
type GlobalSearchResult struct {
	Projects []ProjectDetails `json:"projects"`
	Boards   []RecentBoard    `json:"boards"`
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
