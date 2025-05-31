const Database = require('better-sqlite3');
const path = require('path');

const db = path.join(__dirname, '../manga.db'); // Pfad zur Datenbankdatei

db.prepare(`
CREATE TABLE IF NOT EXISTS mangas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    titel TEXT NOT NULL,
    band INTEGER NOT NULL,
    genre TEXT,
    autor TEXT,
    verlag TEXT,
    isbn TEXT,
    sprache TEXT,
    cover_url TEXT
    read INTEGER DEFAULT 0, -- 0 für false, 1 für true
    double INTEGER DEFAULT 0, -- 0 für false, 1 für true
    new_buy INTEGER DEFAULT 0 -- 0 für false, 1 für true
);
`).run();

module.exports = db;


