package repository

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	_ "github.com/lib/pq"

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
		INSERT INTO users (id, name, email, password_hash, display_name, created_at, updated_at)
		VALUES ($1, $2, LOWER($3), $4, $5, $6, $7)
	`
	if user.ID == uuid.Nil {
		user.ID = uuid.New()
	}
	now := time.Now()
	user.CreatedAt = now
	user.UpdatedAt = now

	_, err := r.db.ExecContext(ctx, query,
		user.ID,
		user.Name,
		user.Email,
		user.PasswordHash,
		user.DisplayName,
		user.CreatedAt,
		user.UpdatedAt,
	)
	return err
}

func (r *PostgresRepository) GetUserByEmail(ctx context.Context, email string) (*models.User, error) {
	query := `
		SELECT id, name, email, password_hash, display_name, created_at, updated_at
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
		&user.CreatedAt,
		&user.UpdatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return user, nil
}

func (r *PostgresRepository) GetUserByID(ctx context.Context, id uuid.UUID) (*models.User, error) {
	query := `
		SELECT id, name, email, password_hash, display_name, created_at, updated_at
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
		&user.CreatedAt,
		&user.UpdatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return user, nil
}

func (r *PostgresRepository) UserExistsByEmail(ctx context.Context, email string) (bool, error) {
	query := `SELECT EXISTS(SELECT 1 FROM users WHERE email = LOWER($1))`
	var exists bool
	err := r.db.QueryRowContext(ctx, query, email).Scan(&exists)
	return exists, err
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

	// 1. Insert Project
	insertProjectQuery := `
		INSERT INTO projects (id, owner_id, name, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5)
	`
	_, err = tx.ExecContext(ctx, insertProjectQuery,
		project.ID,
		project.OwnerID,
		project.Name,
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

func (r *PostgresRepository) ListUserProjects(ctx context.Context, userID uuid.UUID) ([]models.Project, error) {
	query := `
		SELECT p.id, p.owner_id, p.name, p.created_at, p.updated_at
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

	var projects []models.Project
	for rows.Next() {
		var p models.Project
		if err := rows.Scan(&p.ID, &p.OwnerID, &p.Name, &p.CreatedAt, &p.UpdatedAt); err != nil {
			return nil, err
		}
		projects = append(projects, p)
	}
	return projects, nil
}

func (r *PostgresRepository) GetProjectByID(ctx context.Context, projectID uuid.UUID) (*models.Project, error) {
	query := `
		SELECT id, owner_id, name, created_at, updated_at
		FROM projects
		WHERE id = $1
	`
	p := &models.Project{}
	err := r.db.QueryRowContext(ctx, query, projectID).Scan(
		&p.ID,
		&p.OwnerID,
		&p.Name,
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
		       u.name, u.email, u.display_name, u.created_at, u.updated_at
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
			&u.CreatedAt,
			&u.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		u.ID = m.UserID
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
		INSERT INTO boards (id, project_id, name, content, viewport, revision, created_by, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
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

	_, err := r.db.ExecContext(ctx, query,
		board.ID,
		board.ProjectID,
		board.Name,
		board.Content,
		board.Viewport,
		board.Revision,
		board.CreatedBy,
		board.CreatedAt,
		board.UpdatedAt,
	)
	return err
}

func (r *PostgresRepository) ListProjectBoards(ctx context.Context, projectID uuid.UUID) ([]models.Board, error) {
	query := `
		SELECT id, project_id, name, content, viewport, revision, created_by, created_at, updated_at
		FROM boards
		WHERE project_id = $1
		ORDER BY updated_at DESC
	`
	rows, err := r.db.QueryContext(ctx, query, projectID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var boards []models.Board
	for rows.Next() {
		var b models.Board
		err := rows.Scan(
			&b.ID,
			&b.ProjectID,
			&b.Name,
			&b.Content,
			&b.Viewport,
			&b.Revision,
			&b.CreatedBy,
			&b.CreatedAt,
			&b.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		boards = append(boards, b)
	}
	return boards, nil
}

func (r *PostgresRepository) GetBoardByID(ctx context.Context, boardID uuid.UUID) (*models.Board, error) {
	query := `
		SELECT id, project_id, name, content, viewport, revision, created_by, created_at, updated_at
		FROM boards
		WHERE id = $1
	`
	b := &models.Board{}
	err := r.db.QueryRowContext(ctx, query, boardID).Scan(
		&b.ID,
		&b.ProjectID,
		&b.Name,
		&b.Content,
		&b.Viewport,
		&b.Revision,
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

func (r *PostgresRepository) UpdateBoardMetadata(ctx context.Context, boardID uuid.UUID, name string) error {
	query := `
		UPDATE boards
		SET name = $1, updated_at = now()
		WHERE id = $2
	`
	res, err := r.db.ExecContext(ctx, query, name, boardID)
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
	return newRev, err
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
