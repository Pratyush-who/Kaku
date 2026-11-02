-- 01-init.sql
-- Initializes the Kaku PostgreSQL database upon initial container creation.

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    avatar_url TEXT NOT NULL DEFAULT '',
    bio TEXT NOT NULL DEFAULT '',
    preferences JSONB NOT NULL DEFAULT '{"theme":"system","grid":true,"snapToGrid":false,"emailNotifications":true}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Ensure columns exist for existing tables
ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url TEXT NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN IF NOT EXISTS bio TEXT NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN IF NOT EXISTS preferences JSONB NOT NULL DEFAULT '{"theme":"system","grid":true,"snapToGrid":false,"emailNotifications":true}'::jsonb;

CREATE INDEX IF NOT EXISTS idx_users_email ON users(LOWER(email));

-- Projects table
CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    is_public BOOLEAN NOT NULL DEFAULT false,
    public_role VARCHAR(50) NOT NULL DEFAULT 'viewer' CHECK (public_role IN ('viewer', 'editor')),
    share_token VARCHAR(255) NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE projects ADD COLUMN IF NOT EXISTS description TEXT NOT NULL DEFAULT '';
ALTER TABLE projects ADD COLUMN IF NOT EXISTS is_public BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS public_role VARCHAR(50) NOT NULL DEFAULT 'viewer' CHECK (public_role IN ('viewer', 'editor'));
ALTER TABLE projects ADD COLUMN IF NOT EXISTS share_token VARCHAR(255) NOT NULL DEFAULT '';

CREATE INDEX IF NOT EXISTS idx_projects_owner ON projects(owner_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_projects_share_token ON projects(share_token) WHERE share_token != '';
CREATE INDEX IF NOT EXISTS idx_projects_name_lower ON projects(LOWER(name));
CREATE INDEX IF NOT EXISTS idx_users_name_lower ON users(LOWER(name));
CREATE INDEX IF NOT EXISTS idx_users_display_name_lower ON users(LOWER(display_name));

-- Boards table
CREATE TABLE IF NOT EXISTS boards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    content JSONB NOT NULL DEFAULT '{"schemaVersion":1,"elements":[]}'::jsonb,
    viewport JSONB NOT NULL DEFAULT '{"zoom":1.0,"panX":0.0,"panY":0.0}'::jsonb,
    revision BIGINT NOT NULL DEFAULT 0,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_boards_project ON boards(project_id, updated_at DESC);

-- Project Members table
CREATE TABLE IF NOT EXISTS project_members (
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL CHECK (role IN ('owner', 'editor', 'viewer')),
    joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (project_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_project_members_user ON project_members(user_id);

-- Invitations table
CREATE TABLE IF NOT EXISTS invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    role VARCHAR(50) NOT NULL DEFAULT 'editor' CHECK (role IN ('viewer', 'editor')),
    expires_at TIMESTAMPTZ NOT NULL,
    accepted_at TIMESTAMPTZ,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_invitations_token_hash ON invitations(token_hash);
CREATE INDEX IF NOT EXISTS idx_invitations_project ON invitations(project_id);
CREATE INDEX IF NOT EXISTS idx_invitations_email ON invitations(LOWER(email));

-- Board enhancements
ALTER TABLE boards ADD COLUMN IF NOT EXISTS description TEXT NOT NULL DEFAULT '';
ALTER TABLE boards ADD COLUMN IF NOT EXISTS thumbnail TEXT NOT NULL DEFAULT '';
ALTER TABLE boards ADD COLUMN IF NOT EXISTS is_public BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE boards ADD COLUMN IF NOT EXISTS public_role VARCHAR(50) NOT NULL DEFAULT 'viewer' CHECK (public_role IN ('viewer', 'editor'));
ALTER TABLE boards ADD COLUMN IF NOT EXISTS share_token VARCHAR(255) NOT NULL DEFAULT '';
ALTER TABLE boards ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255) NOT NULL DEFAULT '';
ALTER TABLE boards ADD COLUMN IF NOT EXISTS is_trashed BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE boards ADD COLUMN IF NOT EXISTS trashed_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_boards_share_token ON boards(share_token) WHERE share_token != '';
CREATE INDEX IF NOT EXISTS idx_boards_is_trashed ON boards(project_id, is_trashed);

-- Board Elements
CREATE TABLE IF NOT EXISTS board_elements (
    id VARCHAR(255) NOT NULL,
    board_id UUID NOT NULL REFERENCES boards(id) ON DELETE CASCADE,
    type VARCHAR(100) NOT NULL,
    x DOUBLE PRECISION NOT NULL DEFAULT 0,
    y DOUBLE PRECISION NOT NULL DEFAULT 0,
    width DOUBLE PRECISION NOT NULL DEFAULT 0,
    height DOUBLE PRECISION NOT NULL DEFAULT 0,
    angle DOUBLE PRECISION NOT NULL DEFAULT 0,
    stroke_color VARCHAR(50) NOT NULL DEFAULT '#000000',
    background_color VARCHAR(50) NOT NULL DEFAULT 'transparent',
    fill_style VARCHAR(50) NOT NULL DEFAULT 'none',
    stroke_width DOUBLE PRECISION NOT NULL DEFAULT 1,
    stroke_style VARCHAR(50) NOT NULL DEFAULT 'solid',
    roughness DOUBLE PRECISION NOT NULL DEFAULT 1,
    opacity DOUBLE PRECISION NOT NULL DEFAULT 100,
    text TEXT NOT NULL DEFAULT '',
    font_size DOUBLE PRECISION NOT NULL DEFAULT 16,
    font_family VARCHAR(100) NOT NULL DEFAULT 'sans-serif',
    text_align VARCHAR(50) NOT NULL DEFAULT 'left',
    points JSONB NOT NULL DEFAULT '[]'::jsonb,
    properties JSONB NOT NULL DEFAULT '{}'::jsonb,
    z_index BIGINT NOT NULL DEFAULT 0,
    version BIGINT NOT NULL DEFAULT 1,
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    last_modified_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (board_id, id)
);

CREATE INDEX IF NOT EXISTS idx_board_elements_board ON board_elements(board_id, z_index ASC) WHERE is_deleted = false;
CREATE INDEX IF NOT EXISTS idx_board_elements_last_mod ON board_elements(board_id, last_modified_by);

-- Board Versions
CREATE TABLE IF NOT EXISTS board_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    board_id UUID NOT NULL REFERENCES boards(id) ON DELETE CASCADE,
    version_number INT NOT NULL,
    title VARCHAR(255) NOT NULL DEFAULT '',
    description TEXT NOT NULL DEFAULT '',
    content JSONB NOT NULL,
    viewport JSONB NOT NULL DEFAULT '{"zoom":1.0,"panX":0.0,"panY":0.0}'::jsonb,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_board_versions_num ON board_versions(board_id, version_number);
CREATE INDEX IF NOT EXISTS idx_board_versions_board ON board_versions(board_id, created_at DESC);

-- Board Activities
CREATE TABLE IF NOT EXISTS board_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    board_id UUID NOT NULL REFERENCES boards(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    details JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_board_activities_board ON board_activities(board_id, created_at DESC);
