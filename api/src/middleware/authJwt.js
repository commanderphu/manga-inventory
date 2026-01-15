const jwt = require('jsonwebtoken');

/**
 * Middleware to verify JWT token
 * Adds user info to req.user if valid
 */
const verifyToken = (req, res, next) => {
  // Get token from header
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'No token provided'
    });
  }

  // Verify token
  jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
    if (err) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Invalid or expired token'
      });
    }

    // Add user info to request
    req.user = decoded;
    next();
  });
};

/**
 * Optional auth - doesn't fail if no token, but adds user if present
 */
const optionalAuth = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    req.user = null;
    return next();
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
    if (err) {
      req.user = null;
    } else {
      req.user = decoded;
    }
    next();
  });
};

module.exports = {
  verifyToken,
  optionalAuth
};
