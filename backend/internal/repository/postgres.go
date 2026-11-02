package repository

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"

	"github.com/Pratyush-who/Kaku/backend/internal/models"
)

var (
	ErrNotFound       = errors.New("resource not found")
	ErrConflict       = errors.New("resource already exists")
	ErrUnauthorized   = errors.New("unauthorized")
	ErrForbidden      = errors.New("forbidden: insufficient permissions")
	ErrInvalidRequest = errors.New("invalid request")
)

type PostgresRepository struct {
	db *sql.DB
}

func NewPostgresRepository(db *sql.DB) *PostgresRepository {
	return &PostgresRepository{db: db}
}

// User methods

func (r *PostgresRepository) CreateUser(ctx context.Context, user *models.User) error {
	query := `
		INSERT INTO users (id, name, email, password_hash, display_name, avatar_url, bio, preferences, created_at, updated_at)
		VALUES ($1, $2, LOWER($3), $4, $5, $6, $7, $8, $9, $10)
	`
	if user.ID == uuid.Nil {
		user.ID = uuid.New()
	}
	now := time.Now()
	user.CreatedAt = now
	user.UpdatedAt = now
	if len(user.Preferences) == 0 {
		user.Preferences = models.DefaultPreferences
	}

	_, err := r.db.ExecContext(ctx, query,
		user.ID,
		user.Name,
		user.Email,
		user.PasswordHash,
		user.DisplayName,
		user.AvatarURL,
		user.Bio,
		user.Preferences,
		user.CreatedAt,
		user.UpdatedAt,
	)
	return err
}

func (r *PostgresRepository) GetUserByEmail(ctx context.Context, email string) (*models.User, error) {
	query := `
		SELECT id, name, email, password_hash, display_name,
		       COALESCE(avatar_url, ''),
		       COALESCE(bio, ''),
		       COALESCE(preferences, '{"theme":"system","grid":true,"snapToGrid":false,"emailNotifications":true}'::jsonb),
		       created_at, updated_at
		FROM users
		WHERE email = LOWER($1)
	`
	user := &models.User{}
	err := r.db.QueryRowContext(ctx, query, email).Scan(
		&user.ID,
		&user.Name,
		&user.Email,
		&user.PasswordHash,
		&user.DisplayName,
		&user.AvatarURL,
		&user.Bio,
		&user.Preferences,
		&user.CreatedAt,
		&user.UpdatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	if len(user.Preferences) == 0 {
		user.Preferences = models.DefaultPreferences
	}
	return user, nil
}

func (r *PostgresRepository) GetUserByID(ctx context.Context, id uuid.UUID) (*models.User, error) {
	query := `
		SELECT id, name, email, password_hash, display_name,
		       COALESCE(avatar_url, ''),
		       COALESCE(bio, ''),
		       COALESCE(preferences, '{"theme":"system","grid":true,"snapToGrid":false,"emailNotifications":true}'::jsonb),
		       created_at, updated_at
		FROM users
		WHERE id = $1
	`
	user := &models.User{}
	err := r.db.QueryRowContext(ctx, query, id).Scan(
		&user.ID,
		&user.Name,
		&user.Email,
		&user.PasswordHash,
		&user.DisplayName,
		&user.AvatarURL,
		&user.Bio,
		&user.Preferences,
		&user.CreatedAt,
		&user.UpdatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	if len(user.Preferences) == 0 {
		user.Preferences = models.DefaultPreferences
	}
	return user, nil
}

func (r *PostgresRepository) UserExistsByEmail(ctx context.Context, email string) (bool, error) {
	query := `SELECT EXISTS(SELECT 1 FROM users WHERE email = LOWER($1))`
	var exists bool
	err := r.db.QueryRowContext(ctx, query, email).Scan(&exists)
	return exists, err
}

func (r *PostgresRepository) UpdateUserProfile(ctx context.Context, userID uuid.UUID, name, displayName, avatarURL, bio string) (*models.User, error) {
	query := `
		UPDATE users
		SET name = $1, display_name = $2, avatar_url = $3, bio = $4, updated_at = now()
		WHERE id = $5
		RETURNING id, name, email, password_hash, display_name,
		          COALESCE(avatar_url, ''),
		          COALESCE(bio, ''),
		          COALESCE(preferences, '{"theme":"system","grid":true,"snapToGrid":false,"emailNotifications":true}'::jsonb),
		          created_at, updated_at
	`
	user := &models.User{}
	err := r.db.QueryRowContext(ctx, query, name, displayName, avatarURL, bio, userID).Scan(
		&user.ID,
		&user.Name,
		&user.Email,
		&user.PasswordHash,
		&user.DisplayName,
		&user.AvatarURL,
		&user.Bio,
		&user.Preferences,
		&user.CreatedAt,
		&user.UpdatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	if len(user.Preferences) == 0 {
		user.Preferences = models.DefaultPreferences
	}
	return user, nil
}

func (r *PostgresRepository) UpdateUserAvatar(ctx context.Context, userID uuid.UUID, avatarURL string) (*models.User, error) {
	query := `
		UPDATE users
		SET avatar_url = $1, updated_at = now()
		WHERE id = $2
		RETURNING id, name, email, password_hash, display_name,
		          COALESCE(avatar_url, ''),
		          COALESCE(bio, ''),
		          COALESCE(preferences, '{"theme":"system","grid":true,"snapToGrid":false,"emailNotifications":true}'::jsonb),
		          created_at, updated_at
	`
	user := &models.User{}
	err := r.db.QueryRowContext(ctx, query, avatarURL, userID).Scan(
		&user.ID,
		&user.Name,
		&user.Email,
		&user.PasswordHash,
		&user.DisplayName,
		&user.AvatarURL,
		&user.Bio,
		&user.Preferences,
		&user.CreatedAt,
		&user.UpdatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	if len(user.Preferences) == 0 {
		user.Preferences = models.DefaultPreferences
	}
	return user, nil
}

func (r *PostgresRepository) UpdateUserPreferences(ctx context.Context, userID uuid.UUID, preferences json.RawMessage) (*models.User, error) {
	query := `
		UPDATE users
		SET preferences = COALESCE(preferences, '{}'::jsonb) || $1::jsonb, updated_at = now()
		WHERE id = $2
		RETURNING id, name, email, password_hash, display_name,
		          COALESCE(avatar_url, ''),
		          COALESCE(bio, ''),
		          COALESCE(preferences, '{"theme":"system","grid":true,"snapToGrid":false,"emailNotifications":true}'::jsonb),
		          created_at, updated_at
	`
	user := &models.User{}
	err := r.db.QueryRowContext(ctx, query, preferences, userID).Scan(
		&user.ID,
		&user.Name,
		&user.Email,
		&user.PasswordHash,
		&user.DisplayName,
		&user.AvatarURL,
		&user.Bio,
		&user.Preferences,
		&user.CreatedAt,
		&user.UpdatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	if len(user.Preferences) == 0 {
		user.Preferences = models.DefaultPreferences
	}
	return user, nil
}

func (r *PostgresRepository) UpdateUserEmail(ctx context.Context, userID uuid.UUID, newEmail string) (*models.User, error) {
	query := `
		UPDATE users
		SET email = LOWER($1), updated_at = now()
		WHERE id = $2
		RETURNING id, name, email, password_hash, display_name,
		          COALESCE(avatar_url, ''),
		          COALESCE(bio, ''),
		          COALESCE(preferences, '{"theme":"system","grid":true,"snapToGrid":false,"emailNotifications":true}'::jsonb),
		          created_at, updated_at
	`
	user := &models.User{}
	err := r.db.QueryRowContext(ctx, query, newEmail, userID).Scan(
		&user.ID,
		&user.Name,
		&user.Email,
		&user.PasswordHash,
		&user.DisplayName,
		&user.AvatarURL,
		&user.Bio,
		&user.Preferences,
		&user.CreatedAt,
		&user.UpdatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	if len(user.Preferences) == 0 {
		user.Preferences = models.DefaultPreferences
	}
	return user, nil
}

func (r *PostgresRepository) UpdateUserPassword(ctx context.Context, userID uuid.UUID, passwordHash string) error {
	query := `
		UPDATE users
		SET password_hash = $1, updated_at = now()
		WHERE id = $2
	`
	res, err := r.db.ExecContext(ctx, query, passwordHash, userID)
	if err != nil {
		return err
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *PostgresRepository) DeleteUser(ctx context.Context, userID uuid.UUID) error {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	// 1. Delete all projects owned by the user (cascades to project_members, boards, invitations)
	deleteOwnedProjects := `DELETE FROM projects WHERE owner_id = $1`
	if _, err := tx.ExecContext(ctx, deleteOwnedProjects, userID); err != nil {
		return err
	}

	// 2. Remove memberships from projects user didn't own
	deleteMemberships := `DELETE FROM project_members WHERE user_id = $1`
	if _, err := tx.ExecContext(ctx, deleteMemberships, userID); err != nil {
		return err
	}

	// 3. Clear created_by on any remaining boards
	updateBoardCreators := `UPDATE boards SET created_by = NULL WHERE created_by = $1`
	if _, err := tx.ExecContext(ctx, updateBoardCreators, userID); err != nil {
		return err
	}

	// 4. Clear created_by on any remaining invitations
	updateInvCreators := `UPDATE invitations SET created_by = NULL WHERE created_by = $1`
	if _, err := tx.ExecContext(ctx, updateInvCreators, userID); err != nil {
		return err
	}

	// 5. Delete the user
	deleteUser := `DELETE FROM users WHERE id = $1`
	res, err := tx.ExecContext(ctx, deleteUser, userID)
	if err != nil {
		return err
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return ErrNotFound
	}

	return tx.Commit()
}

func (r *PostgresRepository) GetUserStats(ctx context.Context, userID uuid.UUID) (*models.UserStats, error) {
	query := `
		SELECT
			(SELECT COUNT(*) FROM projects WHERE owner_id = $1) AS owned_projects_count,
			(SELECT COUNT(*) FROM project_members WHERE user_id = $1 AND role != 'owner') AS shared_projects_count,
			(SELECT COUNT(*) FROM project_members WHERE user_id = $1) AS total_projects_count,
			(SELECT COUNT(*) FROM boards WHERE created_by = $1) AS created_boards_count,
			(SELECT COUNT(*) FROM boards b INNER JOIN project_members pm ON b.project_id = pm.project_id WHERE pm.user_id = $1) AS total_boards_count,
			(SELECT created_at FROM users WHERE id = $1) AS account_created_at
	`
	stats := &models.UserStats{}
	var createdAt sql.NullTime
	err := r.db.QueryRowContext(ctx, query, userID).Scan(
		&stats.OwnedProjectsCount,
		&stats.SharedProjectsCount,
		&stats.TotalProjectsCount,
		&stats.CreatedBoardsCount,
		&stats.TotalBoardsCount,
		&createdAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	if createdAt.Valid {
		stats.AccountCreatedAt = createdAt.Time
	}
	return stats, nil
}

func (r *PostgresRepository) ListUserRecentBoards(ctx context.Context, userID uuid.UUID, limit, offset int) ([]models.RecentBoard, int, error) {
	if limit <= 0 {
		limit = 10
	}
	if limit > 50 {
		limit = 50
	}
	if offset < 0 {
		offset = 0
	}

	countQuery := `
		SELECT COUNT(*)
		FROM boards b
		INNER JOIN projects p ON b.project_id = p.id
		INNER JOIN project_members pm ON p.id = pm.project_id
		WHERE pm.user_id = $1 AND b.is_trashed = false
	`
	var total int
	if err := r.db.QueryRowContext(ctx, countQuery, userID).Scan(&total); err != nil {
		return nil, 0, err
	}

	query := `
		SELECT b.id, b.project_id, p.name AS project_name, b.name, b.revision, pm.role, b.created_by, b.created_at, b.updated_at
		FROM boards b
		INNER JOIN projects p ON b.project_id = p.id
		INNER JOIN project_members pm ON p.id = pm.project_id
		WHERE pm.user_id = $1 AND b.is_trashed = false
		ORDER BY b.updated_at DESC
		LIMIT $2 OFFSET $3
	`
	rows, err := r.db.QueryContext(ctx, query, userID, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var boards []models.RecentBoard
	for rows.Next() {
		var b models.RecentBoard
		if err := rows.Scan(
			&b.ID,
			&b.ProjectID,
			&b.ProjectName,
			&b.Name,
			&b.Revision,
			&b.Role,
			&b.CreatedBy,
			&b.CreatedAt,
			&b.UpdatedAt,
		); err != nil {
			return nil, 0, err
		}
		boards = append(boards, b)
	}
	if boards == nil {
		boards = []models.RecentBoard{}
	}
	return boards, total, nil
}

// Project methods

func (r *PostgresRepository) CreateProject(ctx context.Context, project *models.Project) error {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	if project.ID == uuid.Nil {
		project.ID = uuid.New()
	}
	now := time.Now()
	project.CreatedAt = now
	project.UpdatedAt = now
	if project.PublicRole == "" {
		project.PublicRole = models.RoleViewer
	}
	if project.ShareToken == "" {
		project.ShareToken = uuid.New().String()
	}

	// 1. Insert Project
	insertProjectQuery := `
		INSERT INTO projects (id, owner_id, name, description, is_public, public_role, share_token, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
	`
	_, err = tx.ExecContext(ctx, insertProjectQuery,
		project.ID,
		project.OwnerID,
		project.Name,
		project.Description,
		project.IsPublic,
		project.PublicRole,
		project.ShareToken,
		project.CreatedAt,
		project.UpdatedAt,
	)
	if err != nil {
		return err
	}

	// 2. Add owner as member with 'owner' role
	insertMemberQuery := `
		INSERT INTO project_members (project_id, user_id, role, joined_at)
		VALUES ($1, $2, $3, $4)
	`
	_, err = tx.ExecContext(ctx, insertMemberQuery,
		project.ID,
		project.OwnerID,
		models.RoleOwner,
		now,
	)
	if err != nil {
		return err
	}

	return tx.Commit()
}

func (r *PostgresRepository) ListUserProjects(ctx context.Context, userID uuid.UUID) ([]models.ProjectDetails, error) {
	query := `
		SELECT p.id, p.owner_id, p.name, COALESCE(p.description, ''), p.is_public, p.public_role, p.share_token, p.created_at, p.updated_at,
		       pm.role,
		       (SELECT COUNT(*) FROM project_members WHERE project_id = p.id) AS member_count,
		       (SELECT COUNT(*) FROM boards WHERE project_id = p.id AND is_trashed = false) AS board_count
		FROM projects p
		INNER JOIN project_members pm ON p.id = pm.project_id
		WHERE pm.user_id = $1
		ORDER BY p.updated_at DESC
	`
	rows, err := r.db.QueryContext(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var projects []models.ProjectDetails
	for rows.Next() {
		var p models.ProjectDetails
		if err := rows.Scan(
			&p.ID,
			&p.OwnerID,
			&p.Name,
			&p.Description,
			&p.IsPublic,
			&p.PublicRole,
			&p.ShareToken,
			&p.CreatedAt,
			&p.UpdatedAt,
			&p.UserRole,
			&p.MemberCount,
			&p.BoardCount,
		); err != nil {
			return nil, err
		}
		if p.ShareToken != "" {
			p.ShareURL = fmt.Sprintf("/shared/projects/%s", p.ShareToken)
		}
		projects = append(projects, p)
	}
	return projects, nil
}

func (r *PostgresRepository) GetProjectDetails(ctx context.Context, projectID, userID uuid.UUID) (*models.ProjectDetails, error) {
	query := `
		SELECT p.id, p.owner_id, p.name, COALESCE(p.description, ''), p.is_public, p.public_role, p.share_token, p.created_at, p.updated_at,
		       pm.role,
		       (SELECT COUNT(*) FROM project_members WHERE project_id = p.id) AS member_count,
		       (SELECT COUNT(*) FROM boards WHERE project_id = p.id AND is_trashed = false) AS board_count
		FROM projects p
		INNER JOIN project_members pm ON p.id = pm.project_id
		WHERE p.id = $1 AND pm.user_id = $2
	`
	p := &models.ProjectDetails{}
	err := r.db.QueryRowContext(ctx, query, projectID, userID).Scan(
		&p.ID,
		&p.OwnerID,
		&p.Name,
		&p.Description,
		&p.IsPublic,
		&p.PublicRole,
		&p.ShareToken,
		&p.CreatedAt,
		&p.UpdatedAt,
		&p.UserRole,
		&p.MemberCount,
		&p.BoardCount,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	if p.ShareToken != "" {
		p.ShareURL = fmt.Sprintf("/shared/projects/%s", p.ShareToken)
	}
	return p, nil
}

func (r *PostgresRepository) GetProjectByID(ctx context.Context, projectID uuid.UUID) (*models.Project, error) {
	query := `
		SELECT id, owner_id, name, COALESCE(description, ''), is_public, public_role, share_token, created_at, updated_at
		FROM projects
		WHERE id = $1
	`
	p := &models.Project{}
	err := r.db.QueryRowContext(ctx, query, projectID).Scan(
		&p.ID,
		&p.OwnerID,
		&p.Name,
		&p.Description,
		&p.IsPublic,
		&p.PublicRole,
		&p.ShareToken,
		&p.CreatedAt,
		&p.UpdatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return p, nil
}

func (r *PostgresRepository) UpdateProjectName(ctx context.Context, projectID uuid.UUID, name string) error {
	query := `
		UPDATE projects
		SET name = $1, updated_at = now()
		WHERE id = $2
	`
	res, err := r.db.ExecContext(ctx, query, name, projectID)
	if err != nil {
		return err
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *PostgresRepository) UpdateProjectMetadata(ctx context.Context, projectID uuid.UUID, name, description string) error {
	query := `
		UPDATE projects
		SET name = CASE WHEN $2 != '' THEN $2 ELSE name END,
		    description = CASE WHEN $3 != '__KEEP__' THEN $3 ELSE description END,
		    updated_at = now()
		WHERE id = $1
	`
	res, err := r.db.ExecContext(ctx, query, projectID, name, description)
	if err != nil {
		return err
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *PostgresRepository) GetProjectByShareToken(ctx context.Context, shareToken string) (*models.Project, error) {
	token := strings.TrimSpace(shareToken)
	if token == "" {
		return nil, ErrNotFound
	}
	query := `
		SELECT id, owner_id, name, COALESCE(description, ''), is_public, public_role, share_token, created_at, updated_at
		FROM projects
		WHERE share_token = $1 AND is_public = true
	`
	p := &models.Project{}
	err := r.db.QueryRowContext(ctx, query, token).Scan(
		&p.ID,
		&p.OwnerID,
		&p.Name,
		&p.Description,
		&p.IsPublic,
		&p.PublicRole,
		&p.ShareToken,
		&p.CreatedAt,
		&p.UpdatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return p, nil
}

func (r *PostgresRepository) UpdateProjectShareSettings(ctx context.Context, projectID uuid.UUID, isPublic bool, publicRole models.ProjectRole, newShareToken string) error {
	if publicRole == "" {
		publicRole = models.RoleViewer
	}
	var query string
	var args []interface{}

	if newShareToken != "" {
		query = `
			UPDATE projects
			SET is_public = $2, public_role = $3, share_token = $4, updated_at = now()
			WHERE id = $1
		`
		args = []interface{}{projectID, isPublic, publicRole, newShareToken}
	} else {
		query = `
			UPDATE projects
			SET is_public = $2, public_role = $3, updated_at = now()
			WHERE id = $1
		`
		args = []interface{}{projectID, isPublic, publicRole}
	}

	res, err := r.db.ExecContext(ctx, query, args...)
	if err != nil {
		return err
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *PostgresRepository) JoinProjectByShareToken(ctx context.Context, shareToken string, userID uuid.UUID) (*models.Project, models.ProjectRole, error) {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return nil, "", err
	}
	defer tx.Rollback()

	query := `
		SELECT id, owner_id, name, COALESCE(description, ''), is_public, public_role, share_token, created_at, updated_at
		FROM projects
		WHERE share_token = $1 AND is_public = true
		FOR UPDATE
	`
	p := &models.Project{}
	err = tx.QueryRowContext(ctx, query, shareToken).Scan(
		&p.ID,
		&p.OwnerID,
		&p.Name,
		&p.Description,
		&p.IsPublic,
		&p.PublicRole,
		&p.ShareToken,
		&p.CreatedAt,
		&p.UpdatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, "", errors.New("shared project not found or link is not active")
	}
	if err != nil {
		return nil, "", err
	}

	// Check if user is already a member
	var existingRole models.ProjectRole
	roleCheckQuery := `SELECT role FROM project_members WHERE project_id = $1 AND user_id = $2`
	err = tx.QueryRowContext(ctx, roleCheckQuery, p.ID, userID).Scan(&existingRole)
	if err == nil {
		// If existing member was viewer and share link offers editor, upgrade role
		if existingRole == models.RoleViewer && p.PublicRole == models.RoleEditor {
			_, _ = tx.ExecContext(ctx, `UPDATE project_members SET role = 'editor' WHERE project_id = $1 AND user_id = $2`, p.ID, userID)
			existingRole = models.RoleEditor
		}
		if err := tx.Commit(); err != nil {
			return nil, "", err
		}
		return p, existingRole, nil
	}

	assignedRole := p.PublicRole
	if assignedRole == "" {
		assignedRole = models.RoleViewer
	}

	insertMember := `
		INSERT INTO project_members (project_id, user_id, role, joined_at)
		VALUES ($1, $2, $3, now())
		ON CONFLICT (project_id, user_id) DO NOTHING
	`
	_, err = tx.ExecContext(ctx, insertMember, p.ID, userID, assignedRole)
	if err != nil {
		return nil, "", err
	}

	if err := tx.Commit(); err != nil {
		return nil, "", err
	}
	return p, assignedRole, nil
}

func (r *PostgresRepository) AddOrUpdateProjectMember(ctx context.Context, projectID, userID uuid.UUID, role models.ProjectRole) error {
	if role != models.RoleEditor && role != models.RoleViewer {
		return errors.New("role must be 'editor' or 'viewer'")
	}

	var ownerID uuid.UUID
	err := r.db.QueryRowContext(ctx, `SELECT owner_id FROM projects WHERE id = $1`, projectID).Scan(&ownerID)
	if err != nil {
		return err
	}
	if ownerID == userID {
		return errors.New("cannot change role of project owner")
	}

	query := `
		INSERT INTO project_members (project_id, user_id, role, joined_at)
		VALUES ($1, $2, $3, now())
		ON CONFLICT (project_id, user_id)
		DO UPDATE SET role = EXCLUDED.role
	`
	_, err = r.db.ExecContext(ctx, query, projectID, userID, role)
	return err
}

func (r *PostgresRepository) UpdateProjectMemberRole(ctx context.Context, projectID, userID uuid.UUID, role models.ProjectRole) error {
	if role != models.RoleEditor && role != models.RoleViewer {
		return errors.New("role must be 'editor' or 'viewer'")
	}

	var ownerID uuid.UUID
	err := r.db.QueryRowContext(ctx, `SELECT owner_id FROM projects WHERE id = $1`, projectID).Scan(&ownerID)
	if err != nil {
		return err
	}
	if ownerID == userID {
		return errors.New("cannot change role of project owner")
	}

	res, err := r.db.ExecContext(ctx, `
		UPDATE project_members
		SET role = $3
		WHERE project_id = $1 AND user_id = $2
	`, projectID, userID, role)
	if err != nil {
		return err
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *PostgresRepository) SearchUsers(ctx context.Context, search string, currentUserID uuid.UUID, projectID *uuid.UUID, limit int) ([]models.UserSearchResult, error) {
	if limit <= 0 || limit > 50 {
		limit = 20
	}
	search = strings.TrimSpace(search)
	if search == "" {
		return []models.UserSearchResult{}, nil
	}

	searchPattern := "%" + strings.ToLower(search) + "%"

	var query string
	var rows *sql.Rows
	var err error

	if projectID != nil && *projectID != uuid.Nil {
		query = `
			SELECT u.id, u.name, u.email, u.display_name, COALESCE(u.avatar_url, ''),
			       CASE WHEN pm.user_id IS NOT NULL THEN true ELSE false END AS is_member,
			       COALESCE(pm.role, '') AS role
			FROM users u
			LEFT JOIN project_members pm ON pm.project_id = $2 AND pm.user_id = u.id
			WHERE (LOWER(u.name) LIKE $1 OR LOWER(u.display_name) LIKE $1 OR LOWER(u.email) LIKE $1)
			ORDER BY 
			    CASE WHEN LOWER(u.email) = LOWER($3) THEN 0
			         WHEN LOWER(u.email) LIKE $1 THEN 1
			         WHEN LOWER(u.display_name) LIKE $1 THEN 2
			         ELSE 3 END,
			    u.display_name ASC
			LIMIT $4
		`
		rows, err = r.db.QueryContext(ctx, query, searchPattern, *projectID, search, limit)
	} else {
		query = `
			SELECT u.id, u.name, u.email, u.display_name, COALESCE(u.avatar_url, ''),
			       false AS is_member,
			       '' AS role
			FROM users u
			WHERE (LOWER(u.name) LIKE $1 OR LOWER(u.display_name) LIKE $1 OR LOWER(u.email) LIKE $1)
			ORDER BY 
			    CASE WHEN LOWER(u.email) = LOWER($2) THEN 0
			         WHEN LOWER(u.email) LIKE $1 THEN 1
			         WHEN LOWER(u.display_name) LIKE $1 THEN 2
			         ELSE 3 END,
			    u.display_name ASC
			LIMIT $3
		`
		rows, err = r.db.QueryContext(ctx, query, searchPattern, search, limit)
	}

	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []models.UserSearchResult
	for rows.Next() {
		var u models.UserSearchResult
		var roleStr string
		if err := rows.Scan(&u.ID, &u.Name, &u.Email, &u.DisplayName, &u.AvatarURL, &u.IsMember, &roleStr); err != nil {
			return nil, err
		}
		u.Role = models.ProjectRole(roleStr)
		results = append(results, u)
	}
	if results == nil {
		results = []models.UserSearchResult{}
	}
	return results, nil
}

func (r *PostgresRepository) SearchProjectsAndBoards(ctx context.Context, userID uuid.UUID, search string, limit int) (*models.GlobalSearchResult, error) {
	if limit <= 0 || limit > 50 {
		limit = 20
	}
	search = strings.TrimSpace(search)
	if search == "" {
		return &models.GlobalSearchResult{
			Projects: []models.ProjectDetails{},
			Boards:   []models.RecentBoard{},
		}, nil
	}

	searchPattern := "%" + strings.ToLower(search) + "%"

	// 1. Matching Projects
	projQuery := `
		SELECT p.id, p.owner_id, p.name, COALESCE(p.description, ''), p.is_public, p.public_role, p.share_token, p.created_at, p.updated_at,
		       pm.role,
		       (SELECT COUNT(*) FROM project_members WHERE project_id = p.id) AS member_count,
		       (SELECT COUNT(*) FROM boards WHERE project_id = p.id AND is_trashed = false) AS board_count
		FROM projects p
		INNER JOIN project_members pm ON p.id = pm.project_id
		WHERE pm.user_id = $1 AND (LOWER(p.name) LIKE $2 OR LOWER(p.description) LIKE $2)
		ORDER BY p.updated_at DESC
		LIMIT $3
	`
	pRows, err := r.db.QueryContext(ctx, projQuery, userID, searchPattern, limit)
	if err != nil {
		return nil, err
	}
	defer pRows.Close()

	var projects []models.ProjectDetails
	for pRows.Next() {
		var p models.ProjectDetails
		if err := pRows.Scan(
			&p.ID,
			&p.OwnerID,
			&p.Name,
			&p.Description,
			&p.IsPublic,
			&p.PublicRole,
			&p.ShareToken,
			&p.CreatedAt,
			&p.UpdatedAt,
			&p.UserRole,
			&p.MemberCount,
			&p.BoardCount,
		); err != nil {
			return nil, err
		}
		if p.ShareToken != "" {
			p.ShareURL = fmt.Sprintf("/shared/projects/%s", p.ShareToken)
		}
		projects = append(projects, p)
	}

	// 2. Matching Boards
	boardQuery := `
		SELECT b.id, b.project_id, p.name AS project_name, b.name, b.revision, pm.role, b.created_by, b.created_at, b.updated_at
		FROM boards b
		INNER JOIN projects p ON b.project_id = p.id
		INNER JOIN project_members pm ON p.id = pm.project_id
		WHERE pm.user_id = $1 AND b.is_trashed = false AND (LOWER(b.name) LIKE $2 OR LOWER(b.description) LIKE $2)
		ORDER BY b.updated_at DESC
		LIMIT $3
	`
	bRows, err := r.db.QueryContext(ctx, boardQuery, userID, searchPattern, limit)
	if err != nil {
		return nil, err
	}
	defer bRows.Close()

	var boards []models.RecentBoard
	for bRows.Next() {
		var b models.RecentBoard
		if err := bRows.Scan(
			&b.ID,
			&b.ProjectID,
			&b.ProjectName,
			&b.Name,
			&b.Revision,
			&b.Role,
			&b.CreatedBy,
			&b.CreatedAt,
			&b.UpdatedAt,
		); err != nil {
			return nil, err
		}
		boards = append(boards, b)
	}

	if projects == nil {
		projects = []models.ProjectDetails{}
	}
	if boards == nil {
		boards = []models.RecentBoard{}
	}

	return &models.GlobalSearchResult{
		Projects: projects,
		Boards:   boards,
	}, nil
}

func (r *PostgresRepository) DeleteProject(ctx context.Context, projectID uuid.UUID) error {
	query := `DELETE FROM projects WHERE id = $1`
	res, err := r.db.ExecContext(ctx, query, projectID)
	if err != nil {
		return err
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

// Membership & Permissions

func (r *PostgresRepository) GetUserProjectRole(ctx context.Context, projectID, userID uuid.UUID) (models.ProjectRole, error) {
	query := `
		SELECT role
		FROM project_members
		WHERE project_id = $1 AND user_id = $2
	`
	var role models.ProjectRole
	err := r.db.QueryRowContext(ctx, query, projectID, userID).Scan(&role)
	if errors.Is(err, sql.ErrNoRows) {
		return "", ErrForbidden
	}
	if err != nil {
		return "", err
	}
	return role, nil
}

func (r *PostgresRepository) ListProjectMembers(ctx context.Context, projectID uuid.UUID) ([]models.ProjectMember, error) {
	query := `
		SELECT pm.project_id, pm.user_id, pm.role, pm.joined_at,
		       u.name, u.email, u.display_name,
		       COALESCE(u.avatar_url, ''),
		       COALESCE(u.bio, ''),
		       COALESCE(u.preferences, '{"theme":"system","grid":true,"snapToGrid":false,"emailNotifications":true}'::jsonb),
		       u.created_at, u.updated_at
		FROM project_members pm
		INNER JOIN users u ON pm.user_id = u.id
		WHERE pm.project_id = $1
		ORDER BY pm.joined_at ASC
	`
	rows, err := r.db.QueryContext(ctx, query, projectID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var members []models.ProjectMember
	for rows.Next() {
		var m models.ProjectMember
		var u models.User
		err := rows.Scan(
			&m.ProjectID,
			&m.UserID,
			&m.Role,
			&m.JoinedAt,
			&u.Name,
			&u.Email,
			&u.DisplayName,
			&u.AvatarURL,
			&u.Bio,
			&u.Preferences,
			&u.CreatedAt,
			&u.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		u.ID = m.UserID
		if len(u.Preferences) == 0 {
			u.Preferences = models.DefaultPreferences
		}
		m.User = &u
		members = append(members, m)
	}
	return members, nil
}

func (r *PostgresRepository) RemoveProjectMember(ctx context.Context, projectID, userID uuid.UUID) error {
	query := `
		DELETE FROM project_members
		WHERE project_id = $1 AND user_id = $2 AND role != 'owner'
	`
	res, err := r.db.ExecContext(ctx, query, projectID, userID)
	if err != nil {
		return err
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return fmt.Errorf("cannot remove owner or member not found")
	}
	return nil
}

// Board methods

func (r *PostgresRepository) CreateBoard(ctx context.Context, board *models.Board) error {
	query := `
		INSERT INTO boards (
			id, project_id, name, description, thumbnail, content, viewport,
			revision, is_public, public_role, share_token, password_hash,
			is_trashed, created_by, created_at, updated_at
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
	`
	if board.ID == uuid.Nil {
		board.ID = uuid.New()
	}
	now := time.Now()
	board.CreatedAt = now
	board.UpdatedAt = now

	if len(board.Content) == 0 {
		board.Content = []byte(`{"schemaVersion":1,"elements":[]}`)
	}
	if len(board.Viewport) == 0 {
		board.Viewport = []byte(`{"zoom":1.0,"panX":0.0,"panY":0.0}`)
	}
	if board.PublicRole == "" {
		board.PublicRole = models.RoleViewer
	}
	if board.ShareToken == "" {
		board.ShareToken = uuid.New().String()
	}

	_, err := r.db.ExecContext(ctx, query,
		board.ID,
		board.ProjectID,
		board.Name,
		board.Description,
		board.Thumbnail,
		board.Content,
		board.Viewport,
		board.Revision,
		board.IsPublic,
		board.PublicRole,
		board.ShareToken,
		board.PasswordHash,
		board.IsTrashed,
		board.CreatedBy,
		board.CreatedAt,
		board.UpdatedAt,
	)
	if err != nil {
		return err
	}

	// Create initial Version 1 snapshot
	initVersion := `
		INSERT INTO board_versions (board_id, version_number, title, description, content, viewport, created_by, created_at)
		VALUES ($1, 1, 'Board Created', 'Initial board canvas', $2, $3, $4, $5)
		ON CONFLICT (board_id, version_number) DO NOTHING
	`
	_, _ = r.db.ExecContext(ctx, initVersion, board.ID, board.Content, board.Viewport, board.CreatedBy, now)
	return nil
}

func (r *PostgresRepository) ListProjectBoardsSummary(ctx context.Context, projectID uuid.UUID) ([]models.BoardSummary, error) {
	query := `
		SELECT id, project_id, name, description, thumbnail, revision,
		       is_public, public_role, share_token, (password_hash != '') AS has_password,
		       is_trashed, trashed_at, created_by, created_at, updated_at
		FROM boards
		WHERE project_id = $1 AND is_trashed = false
		ORDER BY updated_at DESC
	`
	rows, err := r.db.QueryContext(ctx, query, projectID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var boards []models.BoardSummary
	for rows.Next() {
		var b models.BoardSummary
		err := rows.Scan(
			&b.ID,
			&b.ProjectID,
			&b.Name,
			&b.Description,
			&b.Thumbnail,
			&b.Revision,
			&b.IsPublic,
			&b.PublicRole,
			&b.ShareToken,
			&b.HasPassword,
			&b.IsTrashed,
			&b.TrashedAt,
			&b.CreatedBy,
			&b.CreatedAt,
			&b.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		boards = append(boards, b)
	}
	if boards == nil {
		boards = []models.BoardSummary{}
	}
	return boards, nil
}

func (r *PostgresRepository) ListProjectTrashedBoards(ctx context.Context, projectID uuid.UUID) ([]models.BoardSummary, error) {
	query := `
		SELECT id, project_id, name, description, thumbnail, revision,
		       is_public, public_role, share_token, (password_hash != '') AS has_password,
		       is_trashed, trashed_at, created_by, created_at, updated_at
		FROM boards
		WHERE project_id = $1 AND is_trashed = true
		ORDER BY trashed_at DESC
	`
	rows, err := r.db.QueryContext(ctx, query, projectID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var boards []models.BoardSummary
	for rows.Next() {
		var b models.BoardSummary
		err := rows.Scan(
			&b.ID,
			&b.ProjectID,
			&b.Name,
			&b.Description,
			&b.Thumbnail,
			&b.Revision,
			&b.IsPublic,
			&b.PublicRole,
			&b.ShareToken,
			&b.HasPassword,
			&b.IsTrashed,
			&b.TrashedAt,
			&b.CreatedBy,
			&b.CreatedAt,
			&b.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		boards = append(boards, b)
	}
	if boards == nil {
		boards = []models.BoardSummary{}
	}
	return boards, nil
}

func (r *PostgresRepository) DuplicateBoard(ctx context.Context, boardID, userID uuid.UUID, newName string) (*models.Board, error) {
	orig, err := r.GetBoardByID(ctx, boardID)
	if err != nil {
		return nil, err
	}

	if newName == "" {
		newName = orig.Name + " (Copy)"
	}

	clone := &models.Board{
		ID:          uuid.New(),
		ProjectID:   orig.ProjectID,
		Name:        newName,
		Description: orig.Description,
		Thumbnail:   orig.Thumbnail,
		Content:     orig.Content,
		Viewport:    orig.Viewport,
		Revision:    0,
		IsPublic:    false,
		PublicRole:  models.RoleViewer,
		ShareToken:  uuid.New().String(),
		CreatedBy:   &userID,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	if err := r.CreateBoard(ctx, clone); err != nil {
		return nil, err
	}

	// Also clone all existing active board elements
	cloneElementsQuery := `
		INSERT INTO board_elements (
			id, board_id, type, x, y, width, height, angle, stroke_color,
			background_color, fill_style, stroke_width, stroke_style, roughness,
			opacity, text, font_size, font_family, text_align, points, properties,
			z_index, version, is_deleted, created_by, last_modified_by, created_at, updated_at
		)
		SELECT id, $1, type, x, y, width, height, angle, stroke_color,
		       background_color, fill_style, stroke_width, stroke_style, roughness,
		       opacity, text, font_size, font_family, text_align, points, properties,
		       z_index, 1, false, $2, $2, now(), now()
		FROM board_elements
		WHERE board_id = $3 AND is_deleted = false
	`
	_, _ = r.db.ExecContext(ctx, cloneElementsQuery, clone.ID, userID, boardID)

	return clone, nil
}

func (r *PostgresRepository) GetBoardByID(ctx context.Context, boardID uuid.UUID) (*models.Board, error) {
	query := `
		SELECT id, project_id, name, description, thumbnail, content, viewport, revision,
		       is_public, public_role, share_token, (password_hash != '') AS has_password,
		       password_hash, is_trashed, trashed_at, created_by, created_at, updated_at
		FROM boards
		WHERE id = $1
	`
	b := &models.Board{}
	err := r.db.QueryRowContext(ctx, query, boardID).Scan(
		&b.ID,
		&b.ProjectID,
		&b.Name,
		&b.Description,
		&b.Thumbnail,
		&b.Content,
		&b.Viewport,
		&b.Revision,
		&b.IsPublic,
		&b.PublicRole,
		&b.ShareToken,
		&b.HasPassword,
		&b.PasswordHash,
		&b.IsTrashed,
		&b.TrashedAt,
		&b.CreatedBy,
		&b.CreatedAt,
		&b.UpdatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return b, nil
}

func (r *PostgresRepository) GetBoardByShareToken(ctx context.Context, shareToken string) (*models.Board, error) {
	query := `
		SELECT id, project_id, name, description, thumbnail, content, viewport, revision,
		       is_public, public_role, share_token, (password_hash != '') AS has_password,
		       password_hash, is_trashed, trashed_at, created_by, created_at, updated_at
		FROM boards
		WHERE share_token = $1 AND is_trashed = false
	`
	b := &models.Board{}
	err := r.db.QueryRowContext(ctx, query, shareToken).Scan(
		&b.ID,
		&b.ProjectID,
		&b.Name,
		&b.Description,
		&b.Thumbnail,
		&b.Content,
		&b.Viewport,
		&b.Revision,
		&b.IsPublic,
		&b.PublicRole,
		&b.ShareToken,
		&b.HasPassword,
		&b.PasswordHash,
		&b.IsTrashed,
		&b.TrashedAt,
		&b.CreatedBy,
		&b.CreatedAt,
		&b.UpdatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return b, nil
}

func (r *PostgresRepository) UpdateBoardMetadata(ctx context.Context, boardID uuid.UUID, name, description, thumbnail string) error {
	query := `
		UPDATE boards
		SET name = COALESCE(NULLIF($1, ''), name),
		    description = CASE WHEN $2 != '__KEEP__' THEN $2 ELSE description END,
		    thumbnail = CASE WHEN $3 != '__KEEP__' THEN $3 ELSE thumbnail END,
		    updated_at = now()
		WHERE id = $4
	`
	res, err := r.db.ExecContext(ctx, query, name, description, thumbnail, boardID)
	if err != nil {
		return err
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *PostgresRepository) UpdateBoardShareSettings(ctx context.Context, boardID uuid.UUID, isPublic bool, publicRole models.ProjectRole, shareToken, passwordHash string) error {
	query := `
		UPDATE boards
		SET is_public = $1,
		    public_role = $2,
		    share_token = CASE WHEN $3 != '' THEN $3 ELSE share_token END,
		    password_hash = CASE WHEN $4 != '__KEEP__' THEN $4 ELSE password_hash END,
		    updated_at = now()
		WHERE id = $5
	`
	res, err := r.db.ExecContext(ctx, query, isPublic, publicRole, shareToken, passwordHash, boardID)
	if err != nil {
		return err
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *PostgresRepository) TrashBoard(ctx context.Context, boardID uuid.UUID) error {
	query := `
		UPDATE boards
		SET is_trashed = true, trashed_at = now(), updated_at = now()
		WHERE id = $1 AND is_trashed = false
	`
	res, err := r.db.ExecContext(ctx, query, boardID)
	if err != nil {
		return err
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *PostgresRepository) RestoreBoard(ctx context.Context, boardID uuid.UUID) error {
	query := `
		UPDATE boards
		SET is_trashed = false, trashed_at = NULL, updated_at = now()
		WHERE id = $1 AND is_trashed = true
	`
	res, err := r.db.ExecContext(ctx, query, boardID)
	if err != nil {
		return err
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

// UpdateBoardContent updates content and viewport with optimistic concurrency check on expectedRevision
func (r *PostgresRepository) UpdateBoardContent(ctx context.Context, boardID uuid.UUID, content, viewport []byte, expectedRevision int64) (int64, error) {
	return r.UpdateBoardContentWithSnapshot(ctx, boardID, content, viewport, expectedRevision, false, "", nil)
}

// UpdateBoardContentWithSnapshot updates board content and optionally creates a snapshot version
func (r *PostgresRepository) UpdateBoardContentWithSnapshot(ctx context.Context, boardID uuid.UUID, content, viewport []byte, expectedRevision int64, autoSnapshot bool, snapshotTitle string, userID *uuid.UUID) (int64, error) {
	query := `
		UPDATE boards
		SET content = $1, viewport = COALESCE($2, viewport), revision = revision + 1, updated_at = now()
		WHERE id = $3 AND revision = $4
		RETURNING revision
	`
	var newRev int64
	err := r.db.QueryRowContext(ctx, query, content, viewport, boardID, expectedRevision).Scan(&newRev)
	if errors.Is(err, sql.ErrNoRows) {
		return 0, ErrConflict
	}
	if err != nil {
		return 0, err
	}

	if autoSnapshot {
		if snapshotTitle == "" {
			snapshotTitle = fmt.Sprintf("Revision %d Snapshot", newRev)
		}
		vp := viewport
		if len(vp) == 0 {
			vp = []byte(`{"zoom":1.0,"panX":0.0,"panY":0.0}`)
		}
		_ = r.CreateBoardVersion(ctx, &models.BoardVersion{
			BoardID:     boardID,
			Title:       snapshotTitle,
			Description: "Auto-saved snapshot",
			Content:     content,
			Viewport:    vp,
			CreatedBy:   userID,
		})
	}

	return newRev, nil
}

func (r *PostgresRepository) DeleteBoard(ctx context.Context, boardID uuid.UUID) error {
	query := `DELETE FROM boards WHERE id = $1`
	res, err := r.db.ExecContext(ctx, query, boardID)
	if err != nil {
		return err
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

// Element Management Methods

func (r *PostgresRepository) UpsertBoardElements(ctx context.Context, boardID uuid.UUID, elements []models.BoardElement) error {
	if len(elements) == 0 {
		return nil
	}
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	query := `
		INSERT INTO board_elements (
			id, board_id, type, x, y, width, height, angle,
			stroke_color, background_color, fill_style, stroke_width, stroke_style,
			roughness, opacity, text, font_size, font_family, text_align,
			points, properties, z_index, version, is_deleted,
			created_by, last_modified_by, created_at, updated_at
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, now(), now())
		ON CONFLICT (board_id, id) DO UPDATE SET
			type = EXCLUDED.type,
			x = EXCLUDED.x,
			y = EXCLUDED.y,
			width = EXCLUDED.width,
			height = EXCLUDED.height,
			angle = EXCLUDED.angle,
			stroke_color = EXCLUDED.stroke_color,
			background_color = EXCLUDED.background_color,
			fill_style = EXCLUDED.fill_style,
			stroke_width = EXCLUDED.stroke_width,
			stroke_style = EXCLUDED.stroke_style,
			roughness = EXCLUDED.roughness,
			opacity = EXCLUDED.opacity,
			text = EXCLUDED.text,
			font_size = EXCLUDED.font_size,
			font_family = EXCLUDED.font_family,
			text_align = EXCLUDED.text_align,
			points = EXCLUDED.points,
			properties = EXCLUDED.properties,
			z_index = EXCLUDED.z_index,
			version = board_elements.version + 1,
			is_deleted = EXCLUDED.is_deleted,
			last_modified_by = COALESCE(EXCLUDED.last_modified_by, board_elements.last_modified_by),
			updated_at = now()
	`
	stmt, err := tx.PrepareContext(ctx, query)
	if err != nil {
		return err
	}
	defer stmt.Close()

	for _, el := range elements {
		points := el.Points
		if len(points) == 0 {
			points = []byte("[]")
		}
		props := el.Properties
		if len(props) == 0 {
			props = []byte("{}")
		}
		if el.StrokeColor == "" {
			el.StrokeColor = "#000000"
		}
		if el.BackgroundColor == "" {
			el.BackgroundColor = "transparent"
		}
		if el.StrokeWidth <= 0 {
			el.StrokeWidth = 1
		}
		if el.Version <= 0 {
			el.Version = 1
		}
		_, err := stmt.ExecContext(ctx,
			el.ID, boardID, el.Type, el.X, el.Y, el.Width, el.Height, el.Angle,
			el.StrokeColor, el.BackgroundColor, el.FillStyle, el.StrokeWidth, el.StrokeStyle,
			el.Roughness, el.Opacity, el.Text, el.FontSize, el.FontFamily, el.TextAlign,
			points, props, el.ZIndex, el.Version, el.IsDeleted,
			el.CreatedBy, el.LastModifiedBy,
		)
		if err != nil {
			return err
		}
	}

	return tx.Commit()
}

func (r *PostgresRepository) GetBoardElements(ctx context.Context, boardID uuid.UUID) ([]models.BoardElement, error) {
	query := `
		SELECT be.id, be.board_id, be.type, be.x, be.y, be.width, be.height, be.angle,
		       be.stroke_color, be.background_color, be.fill_style, be.stroke_width, be.stroke_style,
		       be.roughness, be.opacity, be.text, be.font_size, be.font_family, be.text_align,
		       be.points, be.properties, be.z_index, be.version, be.is_deleted,
		       be.created_by, COALESCE(u1.display_name, ''),
		       be.last_modified_by, COALESCE(u2.display_name, ''),
		       be.created_at, be.updated_at
		FROM board_elements be
		LEFT JOIN users u1 ON be.created_by = u1.id
		LEFT JOIN users u2 ON be.last_modified_by = u2.id
		WHERE be.board_id = $1 AND be.is_deleted = false
		ORDER BY be.z_index ASC, be.created_at ASC
	`
	rows, err := r.db.QueryContext(ctx, query, boardID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var elements []models.BoardElement
	for rows.Next() {
		var el models.BoardElement
		if err := rows.Scan(
			&el.ID, &el.BoardID, &el.Type, &el.X, &el.Y, &el.Width, &el.Height, &el.Angle,
			&el.StrokeColor, &el.BackgroundColor, &el.FillStyle, &el.StrokeWidth, &el.StrokeStyle,
			&el.Roughness, &el.Opacity, &el.Text, &el.FontSize, &el.FontFamily, &el.TextAlign,
			&el.Points, &el.Properties, &el.ZIndex, &el.Version, &el.IsDeleted,
			&el.CreatedBy, &el.CreatedByName,
			&el.LastModifiedBy, &el.LastModifiedByName,
			&el.CreatedAt, &el.UpdatedAt,
		); err != nil {
			return nil, err
		}
		elements = append(elements, el)
	}
	if elements == nil {
		elements = []models.BoardElement{}
	}
	return elements, nil
}

func (r *PostgresRepository) SoftDeleteBoardElements(ctx context.Context, boardID uuid.UUID, elementIDs []string, modifierID *uuid.UUID) error {
	if len(elementIDs) == 0 {
		return nil
	}
	query := `
		UPDATE board_elements
		SET is_deleted = true, last_modified_by = $1, updated_at = now()
		WHERE board_id = $2 AND id = ANY($3)
	`
	_, err := r.db.ExecContext(ctx, query, modifierID, boardID, pq.Array(elementIDs))
	return err
}

// Version Control / Snapshots

func (r *PostgresRepository) CreateBoardVersion(ctx context.Context, version *models.BoardVersion) error {
	query := `
		INSERT INTO board_versions (id, board_id, version_number, title, description, content, viewport, created_by, created_at)
		VALUES ($1, $2, (SELECT COALESCE(MAX(version_number), 0) + 1 FROM board_versions WHERE board_id = $2), $3, $4, $5, $6, $7, now())
		RETURNING version_number, created_at
	`
	if version.ID == uuid.Nil {
		version.ID = uuid.New()
	}
	if len(version.Viewport) == 0 {
		version.Viewport = []byte(`{"zoom":1.0,"panX":0.0,"panY":0.0}`)
	}
	return r.db.QueryRowContext(ctx, query,
		version.ID, version.BoardID, version.Title, version.Description,
		version.Content, version.Viewport, version.CreatedBy,
	).Scan(&version.VersionNumber, &version.CreatedAt)
}

func (r *PostgresRepository) ListBoardVersions(ctx context.Context, boardID uuid.UUID) ([]models.BoardVersion, error) {
	query := `
		SELECT bv.id, bv.board_id, bv.version_number, bv.title, bv.description, bv.viewport,
		       bv.created_by, COALESCE(u.display_name, ''), bv.created_at
		FROM board_versions bv
		LEFT JOIN users u ON bv.created_by = u.id
		WHERE bv.board_id = $1
		ORDER BY bv.version_number DESC
	`
	rows, err := r.db.QueryContext(ctx, query, boardID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var versions []models.BoardVersion
	for rows.Next() {
		var v models.BoardVersion
		if err := rows.Scan(
			&v.ID, &v.BoardID, &v.VersionNumber, &v.Title, &v.Description, &v.Viewport,
			&v.CreatedBy, &v.CreatedByName, &v.CreatedAt,
		); err != nil {
			return nil, err
		}
		versions = append(versions, v)
	}
	if versions == nil {
		versions = []models.BoardVersion{}
	}
	return versions, nil
}

func (r *PostgresRepository) GetBoardVersionByNumber(ctx context.Context, boardID uuid.UUID, versionNumber int) (*models.BoardVersion, error) {
	query := `
		SELECT bv.id, bv.board_id, bv.version_number, bv.title, bv.description, bv.content, bv.viewport,
		       bv.created_by, COALESCE(u.display_name, ''), bv.created_at
		FROM board_versions bv
		LEFT JOIN users u ON bv.created_by = u.id
		WHERE bv.board_id = $1 AND bv.version_number = $2
	`
	v := &models.BoardVersion{}
	err := r.db.QueryRowContext(ctx, query, boardID, versionNumber).Scan(
		&v.ID, &v.BoardID, &v.VersionNumber, &v.Title, &v.Description, &v.Content, &v.Viewport,
		&v.CreatedBy, &v.CreatedByName, &v.CreatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	return v, err
}

func (r *PostgresRepository) RestoreBoardVersion(ctx context.Context, boardID uuid.UUID, versionNumber int, restoredBy *uuid.UUID) (*models.Board, error) {
	ver, err := r.GetBoardVersionByNumber(ctx, boardID, versionNumber)
	if err != nil {
		return nil, err
	}

	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	// Update board content
	updateQuery := `
		UPDATE boards
		SET content = $1, viewport = $2, revision = revision + 1, updated_at = now()
		WHERE id = $3
		RETURNING revision
	`
	var newRev int64
	if err := tx.QueryRowContext(ctx, updateQuery, ver.Content, ver.Viewport, boardID).Scan(&newRev); err != nil {
		return nil, err
	}

	// Create new version entry for restoration
	restoreVerQuery := `
		INSERT INTO board_versions (board_id, version_number, title, description, content, viewport, created_by, created_at)
		VALUES ($1, (SELECT COALESCE(MAX(version_number), 0) + 1 FROM board_versions WHERE board_id = $1), $2, $3, $4, $5, $6, now())
	`
	title := fmt.Sprintf("Restored from Version %d", versionNumber)
	desc := fmt.Sprintf("Restoration to version: %s", ver.Title)
	if _, err := tx.ExecContext(ctx, restoreVerQuery, boardID, title, desc, ver.Content, ver.Viewport, restoredBy); err != nil {
		return nil, err
	}

	if err := tx.Commit(); err != nil {
		return nil, err
	}

	return r.GetBoardByID(ctx, boardID)
}

// Collaborator & Activity methods

func (r *PostgresRepository) GetBoardContributors(ctx context.Context, boardID uuid.UUID) ([]models.CollaboratorSummary, error) {
	query := `
		SELECT COALESCE(be.last_modified_by, be.created_by) AS user_id,
		       COALESCE(u.name, 'Unknown'),
		       COALESCE(u.display_name, 'Unknown'),
		       COALESCE(u.avatar_url, ''),
		       COUNT(DISTINCT be.id) AS elements_drawn,
		       MAX(be.updated_at) AS last_drew_at
		FROM board_elements be
		LEFT JOIN users u ON u.id = COALESCE(be.last_modified_by, be.created_by)
		WHERE be.board_id = $1 AND be.is_deleted = false AND COALESCE(be.last_modified_by, be.created_by) IS NOT NULL
		GROUP BY user_id, u.name, u.display_name, u.avatar_url
		ORDER BY elements_drawn DESC
	`
	rows, err := r.db.QueryContext(ctx, query, boardID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var contributors []models.CollaboratorSummary
	for rows.Next() {
		var c models.CollaboratorSummary
		if err := rows.Scan(&c.UserID, &c.Name, &c.DisplayName, &c.AvatarURL, &c.ElementsDrawn, &c.LastDrewAt); err != nil {
			return nil, err
		}
		contributors = append(contributors, c)
	}
	if contributors == nil {
		contributors = []models.CollaboratorSummary{}
	}
	return contributors, nil
}

func (r *PostgresRepository) LogBoardActivity(ctx context.Context, act *models.BoardActivity) error {
	query := `
		INSERT INTO board_activities (id, board_id, user_id, action, details, created_at)
		VALUES ($1, $2, $3, $4, $5, now())
	`
	if act.ID == uuid.Nil {
		act.ID = uuid.New()
	}
	details := act.Details
	if len(details) == 0 {
		details = []byte("{}")
	}
	_, err := r.db.ExecContext(ctx, query, act.ID, act.BoardID, act.UserID, act.Action, details)
	return err
}

func (r *PostgresRepository) ListBoardActivities(ctx context.Context, boardID uuid.UUID, limit int) ([]models.BoardActivity, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}
	query := `
		SELECT ba.id, ba.board_id, ba.user_id, COALESCE(u.display_name, 'Guest/System'), ba.action, ba.details, ba.created_at
		FROM board_activities ba
		LEFT JOIN users u ON ba.user_id = u.id
		WHERE ba.board_id = $1
		ORDER BY ba.created_at DESC
		LIMIT $2
	`
	rows, err := r.db.QueryContext(ctx, query, boardID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var activities []models.BoardActivity
	for rows.Next() {
		var a models.BoardActivity
		if err := rows.Scan(&a.ID, &a.BoardID, &a.UserID, &a.UserName, &a.Action, &a.Details, &a.CreatedAt); err != nil {
			return nil, err
		}
		activities = append(activities, a)
	}
	if activities == nil {
		activities = []models.BoardActivity{}
	}
	return activities, nil
}

// Invitations

func (r *PostgresRepository) CreateInvitation(ctx context.Context, inv *models.Invitation) error {
	query := `
		INSERT INTO invitations (id, project_id, email, token_hash, role, expires_at, created_by, created_at)
		VALUES ($1, $2, LOWER($3), $4, $5, $6, $7, $8)
	`
	if inv.ID == uuid.Nil {
		inv.ID = uuid.New()
	}
	now := time.Now()
	inv.CreatedAt = now

	_, err := r.db.ExecContext(ctx, query,
		inv.ID,
		inv.ProjectID,
		inv.Email,
		inv.TokenHash,
		inv.Role,
		inv.ExpiresAt,
		inv.CreatedBy,
		inv.CreatedAt,
	)
	return err
}

func (r *PostgresRepository) ListProjectInvitations(ctx context.Context, projectID uuid.UUID) ([]models.Invitation, error) {
	query := `
		SELECT i.id, i.project_id, i.email, i.role, i.expires_at, i.accepted_at, i.created_by, i.created_at,
		       EXISTS(SELECT 1 FROM users u WHERE LOWER(u.email) = LOWER(i.email)) AS user_exists
		FROM invitations i
		WHERE i.project_id = $1 AND i.accepted_at IS NULL AND i.expires_at > now()
		ORDER BY i.created_at DESC
	`
	rows, err := r.db.QueryContext(ctx, query, projectID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []models.Invitation
	for rows.Next() {
		var inv models.Invitation
		err := rows.Scan(
			&inv.ID,
			&inv.ProjectID,
			&inv.Email,
			&inv.Role,
			&inv.ExpiresAt,
			&inv.AcceptedAt,
			&inv.CreatedBy,
			&inv.CreatedAt,
			&inv.UserExists,
		)
		if err != nil {
			return nil, err
		}
		list = append(list, inv)
	}
	return list, nil
}

func (r *PostgresRepository) GetInvitationByTokenHash(ctx context.Context, tokenHash string) (*models.Invitation, error) {
	query := `
		SELECT i.id, i.project_id, i.email, i.role, i.expires_at, i.accepted_at, i.created_by, i.created_at,
		       EXISTS(SELECT 1 FROM users u WHERE LOWER(u.email) = LOWER(i.email)) AS user_exists
		FROM invitations i
		WHERE i.token_hash = $1
	`
	inv := &models.Invitation{}
	err := r.db.QueryRowContext(ctx, query, tokenHash).Scan(
		&inv.ID,
		&inv.ProjectID,
		&inv.Email,
		&inv.Role,
		&inv.ExpiresAt,
		&inv.AcceptedAt,
		&inv.CreatedBy,
		&inv.CreatedAt,
		&inv.UserExists,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return inv, nil
}

func (r *PostgresRepository) AcceptInvitation(ctx context.Context, tokenHash string, userID uuid.UUID, userEmail string) error {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	query := `
		SELECT id, project_id, email, role, expires_at, accepted_at
		FROM invitations
		WHERE token_hash = $1
		FOR UPDATE
	`
	var inv models.Invitation
	err = tx.QueryRowContext(ctx, query, tokenHash).Scan(
		&inv.ID,
		&inv.ProjectID,
		&inv.Email,
		&inv.Role,
		&inv.ExpiresAt,
		&inv.AcceptedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return ErrNotFound
	}
	if err != nil {
		return err
	}

	if inv.AcceptedAt != nil {
		return errors.New("invitation has already been accepted")
	}
	if time.Now().After(inv.ExpiresAt) {
		return errors.New("invitation has expired")
	}

	// Add member or update role
	insertMember := `
		INSERT INTO project_members (project_id, user_id, role, joined_at)
		VALUES ($1, $2, $3, now())
		ON CONFLICT (project_id, user_id) DO UPDATE SET role = EXCLUDED.role
	`
	_, err = tx.ExecContext(ctx, insertMember, inv.ProjectID, userID, inv.Role)
	if err != nil {
		return err
	}

	// Mark invitation accepted
	updateInv := `
		UPDATE invitations
		SET accepted_at = now()
		WHERE id = $1
	`
	_, err = tx.ExecContext(ctx, updateInv, inv.ID)
	if err != nil {
		return err
	}

	return tx.Commit()
}
