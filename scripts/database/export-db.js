const fs = require('fs');

const supabaseUrl = 'https://zrkbubqsdnomfolywvjr.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpya2J1YnFzZG5vbWZvbHl3dmpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg3Njk5MDQsImV4cCI6MjA2NDM0NTkwNH0.R3xOowCy4K1rShiWMDWq9-c8cy7MvHAXhVq-PSIgKlA';

async function exportDatabase() {
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

  // Create SQL dump
  let sql = `-- Supabase SQL Dump
-- Generated: ${new Date().toISOString()}
-- Database: manga-inventory

-- Create table if not exists
CREATE TABLE IF NOT EXISTS manga (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    titel text NOT NULL,
    band text,
    genre text,
    autor text,
    verlag text,
    isbn text,
    sprache text,
    cover_image text,
    read boolean DEFAULT false,
    double boolean DEFAULT false,
    newbuy boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now())
);

-- Insert data
`;

  // Generate INSERT statements
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
      row.read === null ? 'NULL' : row.read,
      row.double === null ? 'NULL' : row.double,
      row.newbuy === null ? 'NULL' : row.newbuy,
      row.created_at ? `'${row.created_at}'` : 'NULL',
      row.updated_at ? `'${row.updated_at}'` : 'NULL'
    ];

    sql += `INSERT INTO manga (id, titel, band, genre, autor, verlag, isbn, sprache, cover_image, read, double, newbuy, created_at, updated_at) VALUES (${values.join(', ')});\n`;
  }

  // Write to file
  fs.writeFileSync('supabase_dump.sql', sql, 'utf8');
  console.log('SQL dump created successfully: supabase_dump.sql');
  console.log(`Total records exported: ${data.length}`);
}

function escapeSql(str) {
  if (!str) return '';
  return str.replace(/'/g, "''");
}

exportDatabase().catch(console.error);
