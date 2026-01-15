const pool = require('../config/database');
const bcrypt = require('bcrypt');

async function resetPassword(email, newPassword) {
  try {
    // Check if user exists
    const userResult = await pool.query(
      'SELECT id, email, name FROM users WHERE email = $1',
      [email]
    );

    if (userResult.rows.length === 0) {
      console.error(`\nError: No user found with email: ${email}`);
      process.exit(1);
    }

    const user = userResult.rows[0];

    // Hash new password
    const passwordHash = await bcrypt.hash(newPassword, 10);

    // Update password
    await pool.query(
      'UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2',
      [passwordHash, user.id]
    );

    console.log('\n✓ Password reset successfully!');
    console.log(`  User: ${user.name} (${user.email})`);
    console.log(`  New password: ${newPassword}`);
    console.log('');

    process.exit(0);
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

// Get command line arguments
const args = process.argv.slice(2);

if (args.length !== 2) {
  console.log('\nUsage: node reset-password.js <email> <new-password>');
  console.log('Example: node reset-password.js user@example.com MyNewPass123\n');
  process.exit(1);
}

const [email, newPassword] = args;

if (newPassword.length < 6) {
  console.error('\nError: Password must be at least 6 characters long\n');
  process.exit(1);
}

resetPassword(email, newPassword);
