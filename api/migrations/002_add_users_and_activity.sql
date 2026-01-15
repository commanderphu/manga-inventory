-- Migration: Add users and activity tracking
-- Description: Adds multi-user authentication and activity logging

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    avatar_url TEXT,
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Activity log table
CREATE TABLE IF NOT EXISTS activity_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(50) NOT NULL, -- 'created', 'updated', 'deleted', 'marked_read', etc.
    entity_type VARCHAR(50) NOT NULL, -- 'manga', 'user', etc.
    entity_id UUID,
    details JSONB DEFAULT '{}', -- Store what changed
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add user tracking to manga table
ALTER TABLE manga
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES users(id) ON DELETE SET NULL;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_activity_user ON activity_log(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_created ON activity_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_entity ON activity_log(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_manga_created_by ON manga(created_by);
CREATE INDEX IF NOT EXISTS idx_manga_updated_by ON manga(updated_by);

-- Auto-update trigger for users
CREATE OR REPLACE FUNCTION update_users_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_users_updated_at();

-- Sample users (you can change these later)
-- Password is 'manga123' for both (hashed with bcrypt)
INSERT INTO users (email, name, password_hash) VALUES
    ('user1@manga.app', 'User 1', '$2b$10$YourHashHere'), -- Will be replaced with real hash
    ('user2@manga.app', 'User 2', '$2b$10$YourHashHere')
ON CONFLICT (email) DO NOTHING;
