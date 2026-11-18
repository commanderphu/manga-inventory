-- Migration: Konten deaktivieren (#26)
-- NULL = aktiv. Gesetzt = deaktiviert seit diesem Zeitpunkt; Login und
-- bereits ausgestellte Tokens werden dann abgewiesen.

ALTER TABLE users ADD COLUMN IF NOT EXISTS disabled_at TIMESTAMP WITH TIME ZONE;
