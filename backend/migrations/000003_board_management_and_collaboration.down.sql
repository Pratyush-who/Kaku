-- 000003_board_management_and_collaboration.down.sql
DROP TABLE IF EXISTS board_activities;
DROP TABLE IF EXISTS board_versions;
DROP TABLE IF EXISTS board_elements;

ALTER TABLE boards DROP COLUMN IF EXISTS trashed_at;
ALTER TABLE boards DROP COLUMN IF EXISTS is_trashed;
ALTER TABLE boards DROP COLUMN IF EXISTS password_hash;
ALTER TABLE boards DROP COLUMN IF EXISTS share_token;
ALTER TABLE boards DROP COLUMN IF EXISTS public_role;
ALTER TABLE boards DROP COLUMN IF EXISTS is_public;
ALTER TABLE boards DROP COLUMN IF EXISTS thumbnail;
ALTER TABLE boards DROP COLUMN IF EXISTS description;
