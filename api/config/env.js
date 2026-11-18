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

const REGISTRATION_MODES = ['open', 'closed'];

/**
 * Wer darf Konten anlegen? `closed` (Standard): nur der Betreiber per
 * `npm run users -- add`. `open`: jeder über POST /api/auth/register.
 */
function registrationMode() {
  const mode = (process.env.REGISTRATION_MODE || 'closed').trim().toLowerCase();
  if (!REGISTRATION_MODES.includes(mode)) {
    console.error(`❌ REGISTRATION_MODE="${process.env.REGISTRATION_MODE}" ist ungültig, erlaubt: ${REGISTRATION_MODES.join(', ')}`);
    process.exit(1);
  }
  return mode;
}

module.exports = { requireEnv, registrationMode };
