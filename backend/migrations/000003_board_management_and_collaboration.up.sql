-- 000003_board_management_and_collaboration.up.sql
-- Enhances boards table and adds board_elements, board_versions, and board_activities

-- 1. Enhance boards table with metadata, sharing, and trash/restore
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

-- 2. Board Elements table (shapes, text, arrows, images, freehand drawings, with author/provenance tracking)
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

-- 3. Board Versions table (history snapshots & restoration)
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

-- 4. Board Activities table (who joined, who drew, who restored)
CREATE TABLE IF NOT EXISTS board_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    board_id UUID NOT NULL REFERENCES boards(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    details JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_board_activities_board ON board_activities(board_id, created_at DESC);
