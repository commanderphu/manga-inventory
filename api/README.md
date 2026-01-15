# 📚 Manga Inventory REST API

Sichere REST API für die Manga-Sammlung mit PostgreSQL-Backend.

## Features

- ✅ RESTful API mit Express.js
- ✅ PostgreSQL-Datenbankanbindung
- ✅ API-Key-Authentifizierung
- ✅ Rate Limiting
- ✅ CORS-Support für mobile Apps
- ✅ Docker-Support
- ✅ Pagination & Filterung
- ✅ Umfangreiche Sortierung

## API-Endpunkte

### Basis-URL

- **Extern:** `https://manga-api.phudevelopement.xyz`
- **Intern:** `https://manga-api.intern.phudevelopement.xyz`

### Authentifizierung

Alle Requests (außer `/health`) benötigen einen API-Key im Header:

```http
X-API-Key: NTfvGXfVZf3MEgyr56qQbk5Y3Zxfj6A/kI68GnD97hs=
```

### Endpunkte

#### 1. Health Check
```http
GET /health
```

Keine Authentifizierung erforderlich.

**Response:**
```json
{
  "status": "OK",
  "timestamp": "2025-12-31T00:00:00.000Z",
  "uptime": 123.45
}
```

---

#### 2. Manga-Liste abrufen
```http
GET /api/manga
```

**Query Parameter:**

| Parameter | Typ | Beschreibung | Default |
|-----------|-----|--------------|---------|
| `page` | number | Seite | 1 |
| `limit` | number | Einträge pro Seite | 20 |
| `search` | string | Volltext-Suche (Titel, Autor, Genre) | - |
| `genre` | string | Genre-Filter | - |
| `autor` | string | Autor-Filter | - |
| `verlag` | string | Verlag-Filter | - |
| `sprache` | string | Sprache-Filter | - |
| `read` | boolean | Gelesen-Status | - |
| `double` | boolean | Duplikat-Status | - |
| `newbuy` | boolean | Kaufen-Status | - |
| `sortBy` | string | Sortierfeld (titel, autor, band, genre, etc.) | created_at |
| `sortOrder` | string | Sortierrichtung (asc/desc) | desc |

**Response:**
```json
{
  "data": [
    {
      "id": "uuid",
      "titel": "One Piece - 01",
      "band": "1",
      "genre": "Action, Abenteuer",
      "autor": "Eiichiro Oda",
      "verlag": "Carlsen",
      "isbn": "9783551757319",
      "sprache": "Deutsch",
      "cover_image": null,
      "read": false,
      "double": false,
      "newbuy": false,
      "created_at": "2025-01-01T00:00:00.000Z",
      "updated_at": "2025-01-01T00:00:00.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 138,
    "pages": 7
  }
}
```

---

#### 3. Einzelnes Manga abrufen
```http
GET /api/manga/:id
```

**Response:**
```json
{
  "id": "uuid",
  "titel": "One Piece - 01",
  "band": "1",
  ...
}
```

---

#### 4. Neues Manga erstellen
```http
POST /api/manga
```

**Body:**
```json
{
  "titel": "One Piece - 01",
  "band": "1",
  "genre": "Action, Abenteuer",
  "autor": "Eiichiro Oda",
  "verlag": "Carlsen",
  "isbn": "9783551757319",
  "sprache": "Deutsch",
  "cover_image": "https://example.com/cover.jpg",
  "read": false,
  "double": false,
  "newbuy": false
}
```

**Response:** `201 Created`

---

#### 5. Manga aktualisieren
```http
PUT /api/manga/:id
```

**Body:** (alle Felder optional)
```json
{
  "titel": "Updated Title",
  "read": true
}
```

**Response:** `200 OK`

---

#### 6. Manga löschen
```http
DELETE /api/manga/:id
```

**Response:** `200 OK`

---

#### 7. Statistiken abrufen
```http
GET /api/manga/stats/summary
```

**Response:**
```json
{
  "total": "138",
  "read": "22",
  "duplicates": "5",
  "to_buy": "4"
}
```

---

## Deployment

### 1. API bauen und starten

```bash
cd /srv/infra
docker-compose up -d manga-api
```

### 2. Logs anzeigen

```bash
docker logs -f manga_api
```

### 3. API testen

```bash
# Health Check
curl https://manga-api.phudevelopement.xyz/health

# Manga-Liste
curl -H "X-API-Key: NTfvGXfVZf3MEgyr56qQbk5Y3Zxfj6A/kI68GnD97hs=" \
  https://manga-api.phudevelopement.xyz/api/manga
```

---

## Entwicklung

### Lokal starten (ohne Docker)

```bash
cd manga-api
npm install
npm run dev
```

### Environment Variables

Siehe `.env.example` für alle verfügbaren Konfigurationen.

---

## Sicherheit

- ✅ API-Key-Authentifizierung
- ✅ Rate Limiting (100 Requests / 15min)
- ✅ Helmet.js Security Headers
- ✅ CORS-Konfiguration
- ✅ SQL-Injection-Schutz (Prepared Statements)
- ✅ Non-root Docker Container

---

## Flutter-Integration

```dart
class MangaApiClient {
  static const String baseUrl = 'https://manga-api.phudevelopement.xyz';
  static const String apiKey = 'NTfvGXfVZf3MEgyr56qQbk5Y3Zxfj6A/kI68GnD97hs=';

  static Future<List<Manga>> getMangas() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/manga'),
      headers: {'X-API-Key': apiKey},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List)
          .map((m) => Manga.fromJson(m))
          .toList();
    }
    throw Exception('Failed to load mangas');
  }
}
```

---

## Error Handling

Alle Fehler folgen diesem Schema:

```json
{
  "error": "Error Type",
  "message": "Detailed error message"
}
```

**HTTP Status Codes:**
- `200` - OK
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized (kein API-Key)
- `403` - Forbidden (ungültiger API-Key)
- `404` - Not Found
- `429` - Too Many Requests (Rate Limit)
- `500` - Internal Server Error
