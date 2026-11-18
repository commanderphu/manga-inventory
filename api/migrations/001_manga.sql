-- Migration: Grundtabelle manga
-- Bestehende Installationen haben sie schon (IF NOT EXISTS), neue bekommen sie hier.

CREATE TABLE IF NOT EXISTS manga (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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

CREATE INDEX IF NOT EXISTS idx_manga_titel ON manga(titel);
CREATE INDEX IF NOT EXISTS idx_manga_autor ON manga(autor);
CREATE INDEX IF NOT EXISTS idx_manga_genre ON manga(genre);
CREATE INDEX IF NOT EXISTS idx_manga_verlag ON manga(verlag);
CREATE INDEX IF NOT EXISTS idx_manga_isbn ON manga(isbn);
CREATE INDEX IF NOT EXISTS idx_manga_created_at ON manga(created_at DESC);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_manga_updated_at
    BEFORE UPDATE ON manga
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
