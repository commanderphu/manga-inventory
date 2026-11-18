#!/usr/bin/env node
/**
 * Konten verwalten, ohne dass die Registrierung offen sein muss.
 *
 *   npm run users -- list
 *   npm run users -- add <email> <name>
 *   npm run users -- reset-password <email>
 *
 * Im Container: docker exec <container> npm run users -- list
 *
 * Passwörter werden zufällig erzeugt und genau einmal ausgegeben,
 * damit sie nicht in der Shell-Historie landen.
 */
const crypto = require('crypto');
const bcrypt = require('bcrypt');
const pool = require('../config/database');

const USAGE = `Verwendung:
  npm run users -- list
  npm run users -- add <email> <name>
  npm run users -- reset-password <email>`;

function generatePassword() {
  // 18 Bytes → 24 Zeichen base64url, gut abtippbar und ohne Sonderzeichen-Ärger
  return crypto.randomBytes(18).toString('base64url');
}

async function list() {
  const { rows } = await pool.query(
    'SELECT email, name, created_at FROM users ORDER BY created_at'
  );
  if (rows.length === 0) {
    console.log('Noch keine Konten.');
    return;
  }
  for (const u of rows) {
    console.log(`${u.email.padEnd(36)} ${u.name.padEnd(24)} seit ${u.created_at.toISOString().slice(0, 10)}`);
  }
}

async function add(email, name) {
  if (!email || !name) throw new UsageError();
  email = email.trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+$/.test(email)) throw new Error(`"${email}" ist keine gültige E-Mail-Adresse.`);

  const password = generatePassword();
  const hash = await bcrypt.hash(password, 10);
  try {
    await pool.query(
      `INSERT INTO users (email, name, password_hash, settings) VALUES ($1, $2, $3, $4)`,
      [email, name, hash, JSON.stringify({ theme: 'system', notifications: true })]
    );
  } catch (err) {
    if (err.code === '23505') throw new Error(`Es gibt bereits ein Konto mit ${email}.`);
    throw err;
  }
  console.log(`✓ Konto angelegt: ${name} <${email}>`);
  console.log(`  Passwort: ${password}`);
  console.log('  (wird nur jetzt angezeigt)');
}

async function resetPassword(email) {
  if (!email) throw new UsageError();
  const password = generatePassword();
  const hash = await bcrypt.hash(password, 10);
  const { rows } = await pool.query(
    'UPDATE users SET password_hash = $1, updated_at = NOW() WHERE lower(email) = lower($2) RETURNING name, email',
    [hash, email.trim()]
  );
  if (rows.length === 0) throw new Error(`Kein Konto mit ${email}.`);
  console.log(`✓ Neues Passwort für ${rows[0].name} <${rows[0].email}>`);
  console.log(`  Passwort: ${password}`);
  console.log('  (wird nur jetzt angezeigt)');
}

class UsageError extends Error {}

const COMMANDS = { list, add, 'reset-password': resetPassword };

async function main() {
  const [command, ...args] = process.argv.slice(2);
  const run = COMMANDS[command];
  try {
    if (!run) throw new UsageError();
    await run(...args);
  } catch (err) {
    console.error(err instanceof UsageError ? USAGE : `❌ ${err.message}`);
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
}

main();
