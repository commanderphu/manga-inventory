const swaggerJsdoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Manga Inventory API',
      version: '1.0.0',
      description: 'REST API zur Verwaltung der Manga-Sammlung',
    },
    servers: [
      { url: 'https://manga-api.phudevelopement.xyz', description: 'Production' },
      { url: 'http://localhost:3000', description: 'Local' },
    ],
    components: {
      securitySchemes: {
        ApiKeyAuth: {
          type: 'apiKey',
          in: 'header',
          name: 'X-API-Key',
        },
        BearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
      schemas: {
        Manga: {
          type: 'object',
          properties: {
            id: { type: 'integer', example: 1 },
            titel: { type: 'string', example: 'One Piece' },
            band: { type: 'integer', example: 1 },
            genre: { type: 'string', example: 'Shonen' },
            autor: { type: 'string', example: 'Eiichiro Oda' },
            verlag: { type: 'string', example: 'Carlsen' },
            isbn: { type: 'string', example: '978-3551759481' },
            sprache: { type: 'string', example: 'de' },
            cover_image: { type: 'string', example: 'https://...' },
            read: { type: 'boolean', example: false },
            double: { type: 'boolean', example: false },
            newbuy: { type: 'boolean', example: false },
            created_at: { type: 'string', format: 'date-time' },
            updated_at: { type: 'string', format: 'date-time' },
          },
        },
        MangaInput: {
          type: 'object',
          required: ['titel'],
          properties: {
            titel: { type: 'string', example: 'One Piece' },
            band: { type: 'integer', example: 1 },
            genre: { type: 'string', example: 'Shonen' },
            autor: { type: 'string', example: 'Eiichiro Oda' },
            verlag: { type: 'string', example: 'Carlsen' },
            isbn: { type: 'string', example: '978-3551759481' },
            sprache: { type: 'string', example: 'de' },
            cover_image: { type: 'string' },
            read: { type: 'boolean', default: false },
            double: { type: 'boolean', default: false },
            newbuy: { type: 'boolean', default: false },
          },
        },
        User: {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            email: { type: 'string', format: 'email' },
            name: { type: 'string' },
            avatar_url: { type: 'string' },
            settings: { type: 'object' },
            created_at: { type: 'string', format: 'date-time' },
          },
        },
        Error: {
          type: 'object',
          properties: {
            error: { type: 'string' },
            message: { type: 'string' },
          },
        },
      },
    },
    tags: [
      { name: 'Manga', description: 'Manga-Einträge verwalten' },
      { name: 'Auth', description: 'Authentifizierung und Nutzerverwaltung' },
      { name: 'System', description: 'Systemstatus' },
    ],
    paths: {
      '/health': {
        get: {
          tags: ['System'],
          summary: 'Health Check',
          responses: {
            200: { description: 'API läuft' },
          },
        },
      },
      '/api/manga': {
        get: {
          tags: ['Manga'],
          summary: 'Alle Manga auflisten',
          security: [{ ApiKeyAuth: [] }, { BearerAuth: [] }],
          parameters: [
            { name: 'page', in: 'query', schema: { type: 'integer', default: 1 } },
            { name: 'limit', in: 'query', schema: { type: 'integer', default: 20 } },
            { name: 'search', in: 'query', schema: { type: 'string' } },
            { name: 'genre', in: 'query', schema: { type: 'string' } },
            { name: 'autor', in: 'query', schema: { type: 'string' } },
            { name: 'verlag', in: 'query', schema: { type: 'string' } },
            { name: 'sprache', in: 'query', schema: { type: 'string' } },
            { name: 'read', in: 'query', schema: { type: 'boolean' } },
            { name: 'double', in: 'query', schema: { type: 'boolean' } },
            { name: 'newbuy', in: 'query', schema: { type: 'boolean' } },
            { name: 'sortBy', in: 'query', schema: { type: 'string', default: 'created_at' } },
            { name: 'sortOrder', in: 'query', schema: { type: 'string', enum: ['asc', 'desc'], default: 'desc' } },
          ],
          responses: {
            200: {
              description: 'Liste der Manga',
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    properties: {
                      data: { type: 'array', items: { $ref: '#/components/schemas/Manga' } },
                      pagination: {
                        type: 'object',
                        properties: {
                          page: { type: 'integer' },
                          limit: { type: 'integer' },
                          total: { type: 'integer' },
                          pages: { type: 'integer' },
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        },
        post: {
          tags: ['Manga'],
          summary: 'Neuen Manga anlegen',
          security: [{ ApiKeyAuth: [] }, { BearerAuth: [] }],
          requestBody: {
            required: true,
            content: {
              'application/json': { schema: { $ref: '#/components/schemas/MangaInput' } },
            },
          },
          responses: {
            201: { description: 'Manga erstellt', content: { 'application/json': { schema: { $ref: '#/components/schemas/Manga' } } } },
            400: { description: 'Validierungsfehler', content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } } },
          },
        },
      },
      '/api/manga/stats/summary': {
        get: {
          tags: ['Manga'],
          summary: 'Statistiken der Sammlung',
          security: [{ ApiKeyAuth: [] }, { BearerAuth: [] }],
          responses: {
            200: {
              description: 'Statistik',
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    properties: {
                      total: { type: 'string' },
                      read: { type: 'string' },
                      duplicates: { type: 'string' },
                      to_buy: { type: 'string' },
                    },
                  },
                },
              },
            },
          },
        },
      },
      '/api/manga/{id}': {
        get: {
          tags: ['Manga'],
          summary: 'Einzelnen Manga abrufen',
          security: [{ ApiKeyAuth: [] }, { BearerAuth: [] }],
          parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }],
          responses: {
            200: { description: 'Manga', content: { 'application/json': { schema: { $ref: '#/components/schemas/Manga' } } } },
            404: { description: 'Nicht gefunden' },
          },
        },
        put: {
          tags: ['Manga'],
          summary: 'Manga aktualisieren',
          security: [{ ApiKeyAuth: [] }, { BearerAuth: [] }],
          parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }],
          requestBody: {
            content: { 'application/json': { schema: { $ref: '#/components/schemas/MangaInput' } } },
          },
          responses: {
            200: { description: 'Aktualisiert', content: { 'application/json': { schema: { $ref: '#/components/schemas/Manga' } } } },
            404: { description: 'Nicht gefunden' },
          },
        },
        delete: {
          tags: ['Manga'],
          summary: 'Manga löschen',
          security: [{ ApiKeyAuth: [] }, { BearerAuth: [] }],
          parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }],
          responses: {
            200: { description: 'Gelöscht' },
            404: { description: 'Nicht gefunden' },
          },
        },
      },
      '/api/auth/register': {
        post: {
          tags: ['Auth'],
          summary: 'Neuen Nutzer registrieren',
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  required: ['email', 'name', 'password'],
                  properties: {
                    email: { type: 'string', format: 'email' },
                    name: { type: 'string' },
                    password: { type: 'string', minLength: 6 },
                  },
                },
              },
            },
          },
          responses: {
            201: { description: 'Nutzer erstellt + JWT Token' },
            409: { description: 'E-Mail bereits registriert' },
          },
        },
      },
      '/api/auth/login': {
        post: {
          tags: ['Auth'],
          summary: 'Einloggen',
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  required: ['email', 'password'],
                  properties: {
                    email: { type: 'string', format: 'email' },
                    password: { type: 'string' },
                  },
                },
              },
            },
          },
          responses: {
            200: { description: 'Login erfolgreich + JWT Token' },
            401: { description: 'Falsche Zugangsdaten' },
          },
        },
      },
      '/api/auth/me': {
        get: {
          tags: ['Auth'],
          summary: 'Eigenes Profil abrufen',
          security: [{ BearerAuth: [] }],
          responses: {
            200: { description: 'Nutzerprofil', content: { 'application/json': { schema: { $ref: '#/components/schemas/User' } } } },
          },
        },
      },
      '/api/auth/settings': {
        put: {
          tags: ['Auth'],
          summary: 'Einstellungen aktualisieren',
          security: [{ BearerAuth: [] }],
          requestBody: {
            content: { 'application/json': { schema: { type: 'object', properties: { settings: { type: 'object' } } } } },
          },
          responses: { 200: { description: 'Einstellungen gespeichert' } },
        },
      },
      '/api/auth/device-token': {
        post: {
          tags: ['Auth'],
          summary: 'Push-Notification Token registrieren',
          security: [{ BearerAuth: [] }],
          requestBody: {
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  required: ['token', 'deviceType'],
                  properties: {
                    token: { type: 'string' },
                    deviceType: { type: 'string', enum: ['ios', 'android', 'web'] },
                    deviceName: { type: 'string' },
                  },
                },
              },
            },
          },
          responses: { 200: { description: 'Token registriert' } },
        },
        delete: {
          tags: ['Auth'],
          summary: 'Push-Notification Token entfernen',
          security: [{ BearerAuth: [] }],
          requestBody: {
            content: { 'application/json': { schema: { type: 'object', required: ['token'], properties: { token: { type: 'string' } } } } },
          },
          responses: { 200: { description: 'Token entfernt' } },
        },
      },
    },
  },
  apis: [],
};

module.exports = swaggerJsdoc(options);
