const pool = require('../../config/database');

class NotificationService {
  /**
   * Register or update device token for user
   */
  async registerDeviceToken(userId, token, deviceType, deviceName = null) {
    try {
      const result = await pool.query(
        `INSERT INTO device_tokens (user_id, token, device_type, device_name)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (user_id, token)
         DO UPDATE SET
           last_used_at = NOW(),
           device_type = EXCLUDED.device_type,
           device_name = EXCLUDED.device_name
         RETURNING *`,
        [userId, token, deviceType, deviceName]
      );
      return result.rows[0];
    } catch (error) {
      console.error('Error registering device token:', error);
      throw error;
    }
  }

  /**
   * Remove device token
   */
  async removeDeviceToken(userId, token) {
    try {
      await pool.query(
        'DELETE FROM device_tokens WHERE user_id = $1 AND token = $2',
        [userId, token]
      );
    } catch (error) {
      console.error('Error removing device token:', error);
      throw error;
    }
  }

  /**
   * Get all device tokens for a user
   */
  async getUserDeviceTokens(userId) {
    try {
      const result = await pool.query(
        'SELECT * FROM device_tokens WHERE user_id = $1 ORDER BY last_used_at DESC',
        [userId]
      );
      return result.rows;
    } catch (error) {
      console.error('Error getting device tokens:', error);
      throw error;
    }
  }

  /**
   * Send notification to user about manga activity
   */
  async sendMangaActivityNotification(actorUserId, action, mangaTitle, mangaId) {
    try {
      // Get all users except the one who made the change
      const usersResult = await pool.query(
        `SELECT id, name, email FROM users WHERE id != $1`,
        [actorUserId]
      );

      const actorResult = await pool.query(
        'SELECT name FROM users WHERE id = $1',
        [actorUserId]
      );
      const actorName = actorResult.rows[0]?.name || 'Jemand';

      // For each user, check if notifications are enabled
      for (const user of usersResult.rows) {
        // Check user settings
        const settingsResult = await pool.query(
          'SELECT settings FROM users WHERE id = $1',
          [user.id]
        );

        const settings = settingsResult.rows[0]?.settings || {};
        if (settings.notifications === false) {
          continue; // Skip if notifications disabled
        }

        // Get device tokens
        const tokensResult = await pool.query(
          'SELECT token FROM device_tokens WHERE user_id = $1',
          [user.id]
        );

        const tokens = tokensResult.rows.map(row => row.token);

        if (tokens.length === 0) {
          continue; // No tokens to send to
        }

        // Build notification
        const notification = this._buildNotification(action, actorName, mangaTitle);

        // Send FCM notification (if Firebase is configured)
        if (process.env.FIREBASE_SERVER_KEY) {
          await this._sendFCMNotification(tokens, notification, mangaId);
        } else {
          console.log('Firebase not configured. Notification would be:', {
            to: user.email,
            tokens: tokens.length,
            ...notification
          });
        }
      }
    } catch (error) {
      console.error('Error sending notification:', error);
      // Don't throw - notifications should not break the main flow
    }
  }

  /**
   * Build notification message based on action
   */
  _buildNotification(action, actorName, mangaTitle) {
    let title, body;

    switch (action) {
      case 'create':
        title = 'Neuer Manga hinzugefügt';
        body = `${actorName} hat "${mangaTitle}" zur Sammlung hinzugefügt`;
        break;
      case 'update':
        title = 'Manga aktualisiert';
        body = `${actorName} hat "${mangaTitle}" bearbeitet`;
        break;
      case 'delete':
        title = 'Manga entfernt';
        body = `${actorName} hat "${mangaTitle}" aus der Sammlung entfernt`;
        break;
      default:
        title = 'Manga-Aktivität';
        body = `${actorName} hat "${mangaTitle}" geändert`;
    }

    return { title, body };
  }

  /**
   * Send FCM push notification
   */
  async _sendFCMNotification(tokens, notification, mangaId) {
    try {
      const https = require('https');

      const payload = {
        registration_ids: tokens,
        notification: {
          title: notification.title,
          body: notification.body,
          sound: 'default',
          badge: '1',
        },
        data: {
          type: 'manga_activity',
          manga_id: mangaId,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        priority: 'high',
      };

      const data = JSON.stringify(payload);

      const options = {
        hostname: 'fcm.googleapis.com',
        port: 443,
        path: '/fcm/send',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `key=${process.env.FIREBASE_SERVER_KEY}`,
          'Content-Length': data.length,
        },
      };

      return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
          let responseData = '';

          res.on('data', (chunk) => {
            responseData += chunk;
          });

          res.on('end', () => {
            if (res.statusCode === 200) {
              console.log('FCM notification sent successfully:', responseData);
              resolve(JSON.parse(responseData));
            } else {
              console.error('FCM notification failed:', responseData);
              reject(new Error(`FCM error: ${res.statusCode}`));
            }
          });
        });

        req.on('error', (error) => {
          console.error('FCM request error:', error);
          reject(error);
        });

        req.write(data);
        req.end();
      });
    } catch (error) {
      console.error('Error sending FCM notification:', error);
      throw error;
    }
  }
}

module.exports = new NotificationService();
