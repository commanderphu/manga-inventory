const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../../config/database');
const { verifyToken } = require('../middleware/authJwt');

/**
 * POST /api/auth/register
 * Register a new user
 */
router.post('/register', async (req, res) => {
  try {
    const { email, name, password } = req.body;

    // Validation
    if (!email || !name || !password) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Email, name and password are required'
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Password must be at least 6 characters'
      });
    }

    // Check if user exists
    const existingUser = await pool.query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );

    if (existingUser.rows.length > 0) {
      return res.status(409).json({
        error: 'Conflict',
        message: 'Email already registered'
      });
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, 10);

    // Create user
    const result = await pool.query(
      `INSERT INTO users (email, name, password_hash, settings)
       VALUES ($1, $2, $3, $4)
       RETURNING id, email, name, created_at`,
      [email, name, passwordHash, JSON.stringify({ theme: 'system', notifications: true })]
    );

    const user = result.rows[0];

    // Generate token
    const token = jwt.sign(
      { id: user.id, email: user.email, name: user.name },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.status(201).json({
      user: {
        id: user.id,
        email: user.email,
        name: user.name
      },
      token
    });
  } catch (error) {
    console.error('Error in register:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to register user'
    });
  }
});

/**
 * POST /api/auth/login
 * Login user
 */
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validation
    if (!email || !password) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Email and password are required'
      });
    }

    // Find user
    const result = await pool.query(
      'SELECT id, email, name, password_hash, avatar_url, settings FROM users WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Invalid email or password'
      });
    }

    const user = result.rows[0];

    // Check password
    const validPassword = await bcrypt.compare(password, user.password_hash);

    if (!validPassword) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Invalid email or password'
      });
    }

    // Generate token
    const token = jwt.sign(
      { id: user.id, email: user.email, name: user.name },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        avatar_url: user.avatar_url,
        settings: user.settings
      },
      token
    });
  } catch (error) {
    console.error('Error in login:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to login'
    });
  }
});

/**
 * GET /api/auth/me
 * Get current user info
 */
router.get('/me', verifyToken, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, email, name, avatar_url, settings, created_at FROM users WHERE id = $1',
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'User not found'
      });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error in me:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to get user info'
    });
  }
});

/**
 * PUT /api/auth/settings
 * Update user settings
 */
router.put('/settings', verifyToken, async (req, res) => {
  try {
    const { settings } = req.body;

    if (!settings || typeof settings !== 'object') {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Settings object required'
      });
    }

    const result = await pool.query(
      `UPDATE users
       SET settings = $1, updated_at = NOW()
       WHERE id = $2
       RETURNING settings`,
      [JSON.stringify(settings), req.user.id]
    );

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error updating settings:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to update settings'
    });
  }
});

/**
 * POST /api/auth/device-token
 * Register device token for push notifications
 */
router.post('/device-token', verifyToken, async (req, res) => {
  try {
    const { token, deviceType, deviceName } = req.body;

    if (!token || !deviceType) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Token and deviceType are required'
      });
    }

    const notificationService = require('../services/notificationService');
    const result = await notificationService.registerDeviceToken(
      req.user.id,
      token,
      deviceType,
      deviceName
    );

    res.json(result);
  } catch (error) {
    console.error('Error registering device token:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to register device token'
    });
  }
});

/**
 * DELETE /api/auth/device-token
 * Remove device token
 */
router.delete('/device-token', verifyToken, async (req, res) => {
  try {
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Token is required'
      });
    }

    const notificationService = require('../services/notificationService');
    await notificationService.removeDeviceToken(req.user.id, token);

    res.json({ message: 'Device token removed successfully' });
  } catch (error) {
    console.error('Error removing device token:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to remove device token'
    });
  }
});

/**
 * GET /api/auth/device-tokens
 * Get all device tokens for current user
 */
router.get('/device-tokens', verifyToken, async (req, res) => {
  try {
    const notificationService = require('../services/notificationService');
    const tokens = await notificationService.getUserDeviceTokens(req.user.id);

    res.json(tokens);
  } catch (error) {
    console.error('Error getting device tokens:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to get device tokens'
    });
  }
});

module.exports = router;
