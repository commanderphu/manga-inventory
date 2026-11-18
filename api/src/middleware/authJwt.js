const jwt = require('jsonwebtoken');
const pool = require('../../config/database');

function tokenFrom(req) {
  const authHeader = req.headers['authorization'];
  return authHeader && authHeader.split(' ')[1]; // Bearer TOKEN
}

function verifyJwt(token) {
  return new Promise((resolve) => {
    jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => resolve(err ? null : decoded));
  });
}

/**
 * Tokens gelten 30 Tage. Damit ein deaktiviertes oder gelöschtes Konto
 * nicht bis dahin weiterarbeitet, wird bei jeder Anfrage nachgesehen.
 */
async function isActive(userId) {
  const { rows } = await pool.query(
    'SELECT 1 FROM users WHERE id = $1 AND disabled_at IS NULL',
    [userId]
  );
  return rows.length > 0;
}

/**
 * Middleware to verify JWT token
 * Adds user info to req.user if valid
 */
const verifyToken = async (req, res, next) => {
  const token = tokenFrom(req);
  if (!token) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'No token provided'
    });
  }

  const decoded = await verifyJwt(token);
  if (!decoded) {
    return res.status(403).json({
      error: 'Forbidden',
      message: 'Invalid or expired token'
    });
  }

  try {
    if (!(await isActive(decoded.id))) {
      return res.status(401).json({
        error: 'Unauthorized',
        code: 'ACCOUNT_DISABLED',
        message: 'Dieses Konto ist deaktiviert oder existiert nicht mehr.'
      });
    }
  } catch (err) {
    return next(err);
  }

  req.user = decoded;
  next();
};

/**
 * Optional auth - doesn't fail if no token, but adds user if present.
 * Tokens deaktivierter Konten zählen wie gar kein Token.
 */
const optionalAuth = async (req, res, next) => {
  const token = tokenFrom(req);
  const decoded = token ? await verifyJwt(token) : null;

  try {
    req.user = decoded && (await isActive(decoded.id)) ? decoded : null;
  } catch (err) {
    return next(err);
  }
  next();
};

module.exports = {
  verifyToken,
  optionalAuth
};
