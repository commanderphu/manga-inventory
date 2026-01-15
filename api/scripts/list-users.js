const pool = require('../config/database');

async function listUsers() {
  try {
    const result = await pool.query(
      'SELECT id, email, name, created_at FROM users ORDER BY created_at DESC'
    );

    console.log('\n=== Registered Users ===\n');

    if (result.rows.length === 0) {
      console.log('No users found.');
    } else {
      result.rows.forEach((user, index) => {
        console.log(`${index + 1}. Email: ${user.email}`);
        console.log(`   Name: ${user.name}`);
        console.log(`   ID: ${user.id}`);
        console.log(`   Created: ${user.created_at}`);
        console.log('');
      });
    }

    process.exit(0);
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

listUsers();
