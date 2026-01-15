const fs = require('fs');

const supabaseUrl = 'https://zrkbubqsdnomfolywvjr.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpya2J1YnFzZG5vbWZvbHl3dmpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg3Njk5MDQsImV4cCI6MjA2NDM0NTkwNH0.R3xOowCy4K1rShiWMDWq9-c8cy7MvHAXhVq-PSIgKlA';

async function createSQLiteDatabase() {
  console.log('Fetching data from Supabase...');

  // Fetch all manga data using REST API
  const response = await fetch(`${supabaseUrl}/rest/v1/manga?select=*&order=created_at.asc`, {
    headers: {
      'apikey': supabaseKey,
      'Authorization': `Bearer ${supabaseKey}`,
      'Content-Type': 'application/json'
    }
  });

  if (!response.ok) {
    console.error('Error fetching data:', response.statusText);
    process.exit(1);
  }

  const data = await response.json();
  console.log(`Found ${data.length} records`);

  // Create SQLite-compatible SQL dump
  let sql = `-- SQLite Database Dump for Manga Inventory
-- Generated: ${new Date().toISOString()}
-- Total records: ${data.length}

-- Drop table if exists
DROP TABLE IF EXISTS manga;

-- Create manga table
CREATE TABLE manga (
    id TEXT PRIMARY KEY,
    titel TEXT NOT NULL,
    band TEXT,
    genre TEXT,
    autor TEXT,
    verlag TEXT,
    isbn TEXT,
    sprache TEXT,
    cover_image TEXT,
    read INTEGER DEFAULT 0,
    double INTEGER DEFAULT 0,
    newbuy INTEGER DEFAULT 0,
    created_at TEXT,
    updated_at TEXT
);

-- Insert data
BEGIN TRANSACTION;

`;

  // Generate INSERT statements for SQLite
  for (const row of data) {
    const values = [
      `'${row.id}'`,
      `'${escapeSql(row.titel)}'`,
      row.band ? `'${escapeSql(row.band)}'` : 'NULL',
      row.genre ? `'${escapeSql(row.genre)}'` : 'NULL',
      row.autor ? `'${escapeSql(row.autor)}'` : 'NULL',
      row.verlag ? `'${escapeSql(row.verlag)}'` : 'NULL',
      row.isbn ? `'${escapeSql(row.isbn)}'` : 'NULL',
      row.sprache ? `'${escapeSql(row.sprache)}'` : 'NULL',
      row.cover_image ? `'${escapeSql(row.cover_image)}'` : 'NULL',
      row.read === null ? 0 : (row.read ? 1 : 0),
      row.double === null ? 0 : (row.double ? 1 : 0),
      row.newbuy === null ? 0 : (row.newbuy ? 1 : 0),
      row.created_at ? `'${row.created_at}'` : 'NULL',
      row.updated_at ? `'${row.updated_at}'` : 'NULL'
    ];

    sql += `INSERT INTO manga (id, titel, band, genre, autor, verlag, isbn, sprache, cover_image, read, double, newbuy, created_at, updated_at) VALUES (${values.join(', ')});\n`;
  }

  sql += `\nCOMMIT;

-- Create indexes for better performance
CREATE INDEX idx_manga_titel ON manga(titel);
CREATE INDEX idx_manga_autor ON manga(autor);
CREATE INDEX idx_manga_genre ON manga(genre);
CREATE INDEX idx_manga_verlag ON manga(verlag);
CREATE INDEX idx_manga_isbn ON manga(isbn);
`;

  // Write SQL file
  fs.writeFileSync('manga.sql', sql, 'utf8');
  console.log('SQLite SQL file created: manga.sql');
  console.log(`Total records: ${data.length}`);
}

function escapeSql(str) {
  if (!str) return '';
  return str.replace(/'/g, "''");
}

createSQLiteDatabase().catch(console.error);
