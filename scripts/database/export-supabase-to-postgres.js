const fs = require('fs');

const supabaseUrl = 'https://zrkbubqsdnomfolywvjr.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpya2J1YnFzZG5vbWZvbHl3dmpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg3Njk5MDQsImV4cCI6MjA2NDM0NTkwNH0.R3xOowCy4K1rShiWMDWq9-c8cy7MvHAXhVq-PSIgKlA';

async function exportToPostgreSQL() {
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
  console.log(`Found ${data.length} records from Supabase`);

  // Generate PostgreSQL INSERT statements
  let sql = `-- Manga Data Import from Supabase
-- Generated: ${new Date().toISOString()}
-- Total records: ${data.length}

BEGIN TRANSACTION;

`;

  for (const row of data) {
    const values = [
      `'${row.id}'::uuid`,
      `'${escapeSql(row.titel)}'`,
      row.band ? `'${escapeSql(row.band)}'` : 'NULL',
      row.genre ? `'${escapeSql(row.genre)}'` : 'NULL',
      row.autor ? `'${escapeSql(row.autor)}'` : 'NULL',
      row.verlag ? `'${escapeSql(row.verlag)}'` : 'NULL',
      row.isbn ? `'${escapeSql(row.isbn)}'` : 'NULL',
      row.sprache ? `'${escapeSql(row.sprache)}'` : 'NULL',
      row.cover_image ? `'${escapeSql(row.cover_image)}'` : 'NULL',
      row.read === null ? 'false' : (row.read ? 'true' : 'false'),
      row.double === null ? 'false' : (row.double ? 'true' : 'false'),
      row.newbuy === null ? 'false' : (row.newbuy ? 'true' : 'false'),
      row.created_at ? `'${row.created_at}'::timestamp with time zone` : 'CURRENT_TIMESTAMP',
      row.updated_at ? `'${row.updated_at}'::timestamp with time zone` : 'CURRENT_TIMESTAMP'
    ];

    sql += `INSERT INTO manga (id, titel, band, genre, autor, verlag, isbn, sprache, cover_image, read, double, newbuy, created_at, updated_at)
VALUES (${values.join(', ')});\n`;
  }

  sql += `\nCOMMIT;

-- Verify import
SELECT COUNT(*) as total_records FROM manga;
SELECT 'Data import completed successfully!' AS status;
`;

  // Write to file
  fs.writeFileSync('import-manga-data.sql', sql, 'utf8');
  console.log('PostgreSQL import script created: import-manga-data.sql');
  console.log(`Total records to import: ${data.length}`);
}

function escapeSql(str) {
  if (!str) return '';
  return str.replace(/'/g, "''").replace(/\\/g, '\\\\');
}

exportToPostgreSQL().catch(console.error);
