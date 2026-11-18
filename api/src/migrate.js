const fs = require('fs');
const path = require('path');

const MIGRATIONS_DIR = path.join(__dirname, '..', 'migrations');
// Beliebige, feste Zahl: verhindert, dass zwei Instanzen gleichzeitig migrieren
const LOCK_KEY = 420012;

function migrationFiles() {
  return fs
    .readdirSync(MIGRATIONS_DIR)
    .filter((file) => /^\d{3}_[\w-]+\.sql$/.test(file))
    .sort();
}

/**
 * Führt alle noch fehlenden Migrationen aus api/migrations/ in Reihenfolge aus.
 * Jede Migration läuft in einer eigenen Transaktion: Schlägt sie fehl, wird sie
 * komplett zurückgerollt und der Fehler weitergereicht, die API startet dann nicht.
 *
 * Läuft als DB-Benutzer der API, damit neue Tabellen ihm gehören.
 */
async function migrate(pool, log = console.log) {
  const client = await pool.connect();
  try {
    await client.query('SELECT pg_advisory_lock($1)', [LOCK_KEY]);
    await client.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        version TEXT PRIMARY KEY,
        applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )`);

    const { rows } = await client.query('SELECT version FROM schema_migrations');
    const applied = new Set(rows.map((row) => row.version));
    const pending = migrationFiles().filter((file) => !applied.has(path.basename(file, '.sql')));

    for (const file of pending) {
      const version = path.basename(file, '.sql');
      const sql = fs.readFileSync(path.join(MIGRATIONS_DIR, file), 'utf8');
      await client.query('BEGIN');
      try {
        await client.query(sql);
        await client.query('INSERT INTO schema_migrations (version) VALUES ($1)', [version]);
        await client.query('COMMIT');
        log(`✅ Migration ${version} ausgeführt`);
      } catch (err) {
        await client.query('ROLLBACK');
        throw new Error(`Migration ${version} fehlgeschlagen und zurückgerollt: ${err.message}`);
      }
    }

    if (pending.length === 0) log('✅ Datenbankschema ist aktuell');
  } finally {
    await client.query('SELECT pg_advisory_unlock($1)', [LOCK_KEY]).catch(() => {});
    client.release();
  }
}

/**
 * Bricht ab, wenn der DB-Benutzer der API nicht auf allen Tabellen lesen und
 * schreiben darf, statt erst beim ersten Aufruf mit einer 500 zu scheitern.
 */
async function checkPrivileges(pool) {
  const { rows } = await pool.query(`
    SELECT c.relname AS table
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relkind = 'r'
      AND NOT has_table_privilege(current_user, c.oid, 'SELECT, INSERT, UPDATE, DELETE')
    ORDER BY 1`);
  if (rows.length > 0) {
    const tables = rows.map((row) => row.table).join(', ');
    throw new Error(
      `Dem DB-Benutzer fehlen Rechte auf: ${tables}\n` +
      `   Als Superuser beheben, z. B.: ALTER TABLE <tabelle> OWNER TO ${process.env.DB_USER};`
    );
  }
}

module.exports = { migrate, checkPrivileges };
