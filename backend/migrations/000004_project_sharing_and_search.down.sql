-- 000004_project_sharing_and_search.down.sql
DROP INDEX IF EXISTS idx_users_display_name_lower;
DROP INDEX IF EXISTS idx_users_name_lower;
DROP INDEX IF EXISTS idx_projects_name_lower;
DROP INDEX IF EXISTS idx_projects_share_token;

ALTER TABLE projects DROP COLUMN IF EXISTS share_token;
ALTER TABLE projects DROP COLUMN IF EXISTS public_role;
ALTER TABLE projects DROP COLUMN IF EXISTS is_public;
ALTER TABLE projects DROP COLUMN IF EXISTS description;

