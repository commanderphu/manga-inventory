const express = require('express');
const router = express.Router();
const pool = require('../../config/database');

/**
 * GET /api/manga - Get all manga with pagination and filters
 */
router.get('/', async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      search = '',
      genre = '',
      autor = '',
      verlag = '',
      sprache = '',
      read = '',
      double = '',
      newbuy = '',
      sortBy = 'created_at',
      sortOrder = 'desc'
    } = req.query;

    const offset = (page - 1) * limit;

    // Build WHERE clause
    let whereConditions = [];
    let queryParams = [];
    let paramIndex = 1;

    if (search) {
      queryParams.push(`%${search}%`);
      whereConditions.push(`(titel ILIKE $${paramIndex} OR autor ILIKE $${paramIndex} OR genre ILIKE $${paramIndex})`);
      paramIndex++;
    }

    if (genre) {
      queryParams.push(`%${genre}%`);
      whereConditions.push(`genre ILIKE $${paramIndex}`);
      paramIndex++;
    }

    if (autor) {
      queryParams.push(`%${autor}%`);
      whereConditions.push(`autor ILIKE $${paramIndex}`);
      paramIndex++;
    }

    if (verlag) {
      queryParams.push(`%${verlag}%`);
      whereConditions.push(`verlag ILIKE $${paramIndex}`);
      paramIndex++;
    }

    if (sprache) {
      queryParams.push(sprache);
      whereConditions.push(`sprache = $${paramIndex}`);
      paramIndex++;
    }

    if (read !== '') {
      queryParams.push(read === 'true');
      whereConditions.push(`read = $${paramIndex}`);
      paramIndex++;
    }

    if (double !== '') {
      queryParams.push(double === 'true');
      whereConditions.push(`double = $${paramIndex}`);
      paramIndex++;
    }

    if (newbuy !== '') {
      queryParams.push(newbuy === 'true');
      whereConditions.push(`newbuy = $${paramIndex}`);
      paramIndex++;
    }

    const whereClause = whereConditions.length > 0
      ? `WHERE ${whereConditions.join(' AND ')}`
      : '';

    // Validate sortBy to prevent SQL injection
    const validSortFields = ['titel', 'autor', 'band', 'genre', 'verlag', 'sprache', 'created_at', 'updated_at'];
    const sortField = validSortFields.includes(sortBy) ? sortBy : 'created_at';
    const order = sortOrder.toLowerCase() === 'asc' ? 'ASC' : 'DESC';

    // Get total count
    const countQuery = `SELECT COUNT(*) FROM manga ${whereClause}`;
    const countResult = await pool.query(countQuery, queryParams);
    const total = parseInt(countResult.rows[0].count);

    // Get manga data
    queryParams.push(limit, offset);
    const dataQuery = `
      SELECT * FROM manga
      ${whereClause}
      ORDER BY ${sortField} ${order}
      LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
    `;

    const result = await pool.query(dataQuery, queryParams);

    res.json({
      data: result.rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });

  } catch (error) {
    console.error('Error fetching manga:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

/**
 * GET /api/manga/:id - Get single manga by ID
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      'SELECT * FROM manga WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Manga not found'
      });
    }

    res.json(result.rows[0]);

  } catch (error) {
    console.error('Error fetching manga:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

/**
 * POST /api/manga - Create new manga
 */
router.post('/', async (req, res) => {
  try {
    const {
      titel,
      band,
      genre,
      autor,
      verlag,
      isbn,
      sprache,
      cover_image,
      read = false,
      double = false,
      newbuy = false
    } = req.body;

    if (!titel) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Titel is required'
      });
    }

    const userId = req.user ? req.user.id : null;

    const result = await pool.query(
      `INSERT INTO manga (titel, band, genre, autor, verlag, isbn, sprache, cover_image, read, double, newbuy, created_by, updated_by)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
       RETURNING *`,
      [titel, band, genre, autor, verlag, isbn, sprache, cover_image, read, double, newbuy, userId, userId]
    );

    if (userId) {
      await pool.query(
        `INSERT INTO activity_log (user_id, action, entity_type, entity_id, details)
         VALUES ($1, $2, $3, $4, $5)`,
        [userId, 'create', 'manga', result.rows[0].id, JSON.stringify({ titel })]
      );

      // Send notification to other users
      const notificationService = require('../services/notificationService');
      await notificationService.sendMangaActivityNotification(
        userId,
        'create',
        titel,
        result.rows[0].id
      );
    }

    res.status(201).json(result.rows[0]);

  } catch (error) {
    console.error('Error creating manga:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

/**
 * PUT /api/manga/:id - Update manga
 */
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const {
      titel,
      band,
      genre,
      autor,
      verlag,
      isbn,
      sprache,
      cover_image,
      read,
      double,
      newbuy
    } = req.body;

    const userId = req.user ? req.user.id : null;

    const result = await pool.query(
      `UPDATE manga
       SET titel = COALESCE($1, titel),
           band = COALESCE($2, band),
           genre = COALESCE($3, genre),
           autor = COALESCE($4, autor),
           verlag = COALESCE($5, verlag),
           isbn = COALESCE($6, isbn),
           sprache = COALESCE($7, sprache),
           cover_image = COALESCE($8, cover_image),
           read = COALESCE($9, read),
           double = COALESCE($10, double),
           newbuy = COALESCE($11, newbuy),
           updated_by = $12,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $13
       RETURNING *`,
      [titel, band, genre, autor, verlag, isbn, sprache, cover_image, read, double, newbuy, userId, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Manga not found'
      });
    }

    if (userId) {
      await pool.query(
        `INSERT INTO activity_log (user_id, action, entity_type, entity_id, details)
         VALUES ($1, $2, $3, $4, $5)`,
        [userId, 'update', 'manga', id, JSON.stringify({ titel: result.rows[0].titel })]
      );

      // Send notification to other users
      const notificationService = require('../services/notificationService');
      await notificationService.sendMangaActivityNotification(
        userId,
        'update',
        result.rows[0].titel,
        id
      );
    }

    res.json(result.rows[0]);

  } catch (error) {
    console.error('Error updating manga:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

/**
 * DELETE /api/manga/:id - Delete manga
 */
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user ? req.user.id : null;

    const result = await pool.query(
      'DELETE FROM manga WHERE id = $1 RETURNING *',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Manga not found'
      });
    }

    if (userId) {
      await pool.query(
        `INSERT INTO activity_log (user_id, action, entity_type, entity_id, details)
         VALUES ($1, $2, $3, $4, $5)`,
        [userId, 'delete', 'manga', id, JSON.stringify({ titel: result.rows[0].titel })]
      );

      // Send notification to other users
      const notificationService = require('../services/notificationService');
      await notificationService.sendMangaActivityNotification(
        userId,
        'delete',
        result.rows[0].titel,
        id
      );
    }

    res.json({
      message: 'Manga deleted successfully',
      data: result.rows[0]
    });

  } catch (error) {
    console.error('Error deleting manga:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

/**
 * GET /api/manga/stats - Get statistics
 */
router.get('/stats/summary', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        COUNT(*) as total,
        COUNT(CASE WHEN read = true THEN 1 END) as read,
        COUNT(CASE WHEN double = true THEN 1 END) as duplicates,
        COUNT(CASE WHEN newbuy = true THEN 1 END) as to_buy
      FROM manga
    `);

    res.json(result.rows[0]);

  } catch (error) {
    console.error('Error fetching stats:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

module.exports = router;
