#!/usr/bin/env node

const bcrypt = require('bcrypt');
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST || 'central_postgres',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'manga_inventory',
  user: process.env.DB_USER || 'manga_admin',
  password: process.env.DB_PASSWORD,
});

async function createUsers() {
  console.log('Creating user accounts...\n');

  // Generate password hashes
  const phuPassword = await bcrypt.hash('phu123', 10);
  const jessiPassword = await bcrypt.hash('jessi123', 10);

  try {
    // Check if users table exists
    const tableCheck = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_name = 'users'
      );
    `);

    if (!tableCheck.rows[0].exists) {
      console.log('Users table does not exist. Please run migration first.');
      console.log('Run the migration: psql -h localhost -U manga_admin -d manga_inventory -f migrations/002_add_users_and_activity.sql');
      process.exit(1);
    }

    // Insert or update users
    await pool.query(`
      INSERT INTO users (email, name, password_hash, settings)
      VALUES
        ($1, $2, $3, $4),
        ($5, $6, $7, $8)
      ON CONFLICT (email)
      DO UPDATE SET
        password_hash = EXCLUDED.password_hash,
        updated_at = NOW()
    `, [
      'phu@phudevelopement.xyz', 'Phu', phuPassword, JSON.stringify({ theme: 'system', notifications: true }),
      'jessi@phudevelopement.xyz', 'Jessi', jessiPassword, JSON.stringify({ theme: 'system', notifications: true })
    ]);

    console.log('✓ User accounts created successfully!\n');
    console.log('Login credentials:');
    console.log('  Phu:');
    console.log('    Email: phu@phudevelopement.xyz');
    console.log('    Password: phu123');
    console.log('');
    console.log('  Jessi:');
    console.log('    Email: jessi@phudevelopement.xyz');
    console.log('    Password: jessi123');
    console.log('');
    console.log('⚠️  Please change these passwords after first login!');

  } catch (error) {
    console.error('Error creating users:', error.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

createUsers();
