const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST || 'central_postgres',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'manga_inventory',
  user: process.env.DB_USER || 'manga_admin',
  password: process.env.DB_PASSWORD || 'manga_secure_2025',
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Test connection
pool.on('connect', () => {
  console.log('✅ Connected to PostgreSQL database');
});

pool.on('error', (err) => {
  console.error('❌ Unexpected error on idle client', err);
  process.exit(-1);
});

module.exports = pool;
