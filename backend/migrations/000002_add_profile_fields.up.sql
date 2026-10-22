-- 000002_add_profile_fields.up.sql
-- Add profile customization fields to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url TEXT NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN IF NOT EXISTS bio TEXT NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN IF NOT EXISTS preferences JSONB NOT NULL DEFAULT '{"theme":"system","grid":true,"snapToGrid":false,"emailNotifications":true}'::jsonb;
