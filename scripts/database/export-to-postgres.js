const fs = require('fs');
const { execSync } = require('child_process');

console.log('Reading data from SQLite database...');

// Query SQLite database
const query = 'SELECT * FROM manga ORDER BY created_at ASC';
const result = execSync(`sqlite3 manga.db "${query}"`, { encoding: 'utf8' });

// Parse SQLite output (pipe-separated values)
const lines = result.trim().split('\n');
const records = lines.map(line => {
  const fields = line.split('|');
  return {
    id: fields[0],
    titel: fields[1],
    band: fields[2] || null,
    genre: fields[3] || null,
    autor: fields[4] || null,
    verlag: fields[5] || null,
    isbn: fields[6] || null,
    sprache: fields[7] || null,
    cover_image: fields[8] || null,
    read: fields[9] === '1',
    double: fields[10] === '1',
    newbuy: fields[11] === '1',
    created_at: fields[12] || null,
    updated_at: fields[13] || null
  };
});

console.log(`Found ${records.length} records`);

// Generate PostgreSQL INSERT statements
let sql = `-- Manga Data Import
-- Generated: ${new Date().toISOString()}
-- Total records: ${records.length}

BEGIN TRANSACTION;

`;

for (const row of records) {
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
    row.read ? 'true' : 'false',
    row.double ? 'true' : 'false',
    row.newbuy ? 'true' : 'false',
    row.created_at ? `'${row.created_at}'` : 'CURRENT_TIMESTAMP',
    row.updated_at ? `'${row.updated_at}'` : 'CURRENT_TIMESTAMP'
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
console.log(`Total records to import: ${records.length}`);

function escapeSql(str) {
  if (!str) return '';
  return str.replace(/'/g, "''").replace(/\\/g, '\\\\');
}
