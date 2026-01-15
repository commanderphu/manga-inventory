-- ======================================================
-- 📚 Manga Inventory Database Setup
-- Created: 2025-12-31
-- ======================================================

-- Create dedicated user for manga app
CREATE USER manga_admin WITH PASSWORD 'manga_secure_2025';

-- Create manga database
CREATE DATABASE manga_inventory OWNER manga_admin;

-- Grant all privileges
GRANT ALL PRIVILEGES ON DATABASE manga_inventory TO manga_admin;

-- Set UTF8 encoding
ALTER DATABASE manga_inventory SET client_encoding TO 'UTF8';

-- Connect to manga database
\c manga_inventory

-- Create manga table with PostgreSQL UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop table if exists (for clean reinstall)
DROP TABLE IF EXISTS manga;

-- Create manga table
CREATE TABLE manga (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    titel TEXT NOT NULL,
    band TEXT,
    genre TEXT,
    autor TEXT,
    verlag TEXT,
    isbn TEXT,
    sprache TEXT,
    cover_image TEXT,
    read BOOLEAN DEFAULT false,
    double BOOLEAN DEFAULT false,
    newbuy BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX idx_manga_titel ON manga(titel);
CREATE INDEX idx_manga_autor ON manga(autor);
CREATE INDEX idx_manga_genre ON manga(genre);
CREATE INDEX idx_manga_verlag ON manga(verlag);
CREATE INDEX idx_manga_isbn ON manga(isbn);
CREATE INDEX idx_manga_created_at ON manga(created_at DESC);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_manga_updated_at BEFORE UPDATE ON manga
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions
GRANT ALL PRIVILEGES ON TABLE manga TO manga_admin;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO manga_admin;

-- Success message
SELECT 'Manga database setup completed successfully!' AS status;
