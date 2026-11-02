-- 000004_project_sharing_and_search.up.sql
-- Add project-level sharing, description, public access roles, and search indexes

ALTER TABLE projects ADD COLUMN IF NOT EXISTS description TEXT NOT NULL DEFAULT '';
ALTER TABLE projects ADD COLUMN IF NOT EXISTS is_public BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS public_role VARCHAR(50) NOT NULL DEFAULT 'viewer' CHECK (public_role IN ('viewer', 'editor'));
ALTER TABLE projects ADD COLUMN IF NOT EXISTS share_token VARCHAR(255) NOT NULL DEFAULT '';

-- Populate empty share tokens for existing projects with random UUID
UPDATE projects SET share_token = gen_random_uuid()::text WHERE share_token = '';

CREATE INDEX IF NOT EXISTS idx_projects_share_token ON projects(share_token) WHERE share_token != '';
CREATE INDEX IF NOT EXISTS idx_projects_name_lower ON projects(LOWER(name));
CREATE INDEX IF NOT EXISTS idx_users_name_lower ON users(LOWER(name));
CREATE INDEX IF NOT EXISTS idx_users_display_name_lower ON users(LOWER(display_name));

