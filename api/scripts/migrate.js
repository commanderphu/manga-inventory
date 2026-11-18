#!/usr/bin/env node
/**
 * Migrationen von Hand ausführen (die API macht das sonst beim Start selbst).
 *   npm run migrate            fehlende ausführen
 *   npm run migrate -- status  nur anzeigen
 */
const pool = require('../config/database');
const { migrate, checkPrivileges } = require('../src/migrate');

async function status() {
  const { rows } = await pool.query(
    "SELECT to_regclass('schema_migrations') IS NOT NULL AS exists"
  );
  const applied = rows[0].exists
    ? (await pool.query('SELECT version, applied_at FROM schema_migrations ORDER BY version')).rows
    : [];
  const done = new Set(applied.map((r) => r.version));
  for (const r of applied) console.log(`✓ ${r.version}  ${r.applied_at.toISOString().slice(0, 16)}`);
  const fs = require('fs');
  const path = require('path');
  fs.readdirSync(path.join(__dirname, '..', 'migrations'))
    .filter((f) => /^\d{3}_[\w-]+\.sql$/.test(f))
    .sort()
    .map((f) => path.basename(f, '.sql'))
    .filter((v) => !done.has(v))
    .forEach((v) => console.log(`· ${v}  ausstehend`));
}

(async () => {
  try {
    if (process.argv[2] === 'status') {
      await status();
    } else {
      await migrate(pool);
      await checkPrivileges(pool);
    }
  } catch (err) {
    console.error(`❌ ${err.message}`);
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
})();
