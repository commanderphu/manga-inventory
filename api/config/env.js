const path = require('path');

// .env neben package.json laden, egal aus welchem Verzeichnis gestartet wird.
// Bereits gesetzte Variablen (Docker, Makefile) haben Vorrang.
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

/**
 * Bricht mit einer verständlichen Meldung ab, wenn Pflichtvariablen fehlen.
 * Lieber gar nicht starten als still mit falschen Werten.
 */
function requireEnv(names) {
  const missing = names.filter((name) => !process.env[name]);
  if (missing.length > 0) {
    console.error(`❌ Fehlende Umgebungsvariablen: ${missing.join(', ')}`);
    console.error('   Vorlage: api/.env.example');
    process.exit(1);
  }
}

module.exports = { requireEnv };
