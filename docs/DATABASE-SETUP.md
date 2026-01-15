# Manga Inventory - PostgreSQL Database Setup

Erstellt: 2025-12-31

## Übersicht

Die Manga-Sammlung wurde erfolgreich in deine Homelab PostgreSQL-Datenbank migriert.

## Datenbank-Details

### Verbindungsinformationen

```yaml
Host: central_postgres (Docker Container)
Port: 5432
Database: manga_inventory
User: manga_admin
Password: manga_secure_2025
```

### Docker-Zugriff

```bash
# Verbindung über Docker
docker exec -it central_postgres psql -U manga_admin -d manga_inventory

# Oder als admin
docker exec -it central_postgres psql -U admin -d manga_inventory
```

### Verbindungs-URL

```
postgresql://manga_admin:manga_secure_2025@central_postgres:5432/manga_inventory
```

Für externe Verbindung (falls exposed):
```
postgresql://manga_admin:manga_secure_2025@localhost:5432/manga_inventory
```

## Datenbankschema

```sql
CREATE TABLE manga (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    titel TEXT NOT NULL,
    band TEXT,
    genre TEXT,
    autor TEXT,
    verlag TEXT,
    isbn TEXT,
    sprache TEXT,
    cover_image TEXT,
    read BOOLEAN DEFAULT false,
    double BOOLEAN DEFAULT false,
    newbuy BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### Indizes

- `idx_manga_titel` - Titel-Suche
- `idx_manga_autor` - Autor-Filter
- `idx_manga_genre` - Genre-Filter
- `idx_manga_verlag` - Verlag-Filter
- `idx_manga_isbn` - ISBN-Lookup
- `idx_manga_created_at` - Zeitliche Sortierung

### Trigger

`update_manga_updated_at` - Aktualisiert automatisch `updated_at` bei jedem UPDATE

## Daten-Migration

### Import-Statistik

- **Quelle:** Supabase Cloud Database
- **Datum:** 2025-12-31
- **Datensätze:** 138 Manga
  - 22 gelesen
  - 5 Duplikate
  - 4 zum Kaufen markiert

### Migration-Scripts

1. `export-supabase-to-postgres.js` - Exportiert Daten von Supabase
2. `setup-postgres-manga.sql` - Erstellt Datenbank und Schema
3. `import-manga-data.sql` - Importiert die Daten (generiert)

## Flutter-App Konfiguration

### Dart PostgreSQL Package

```yaml
dependencies:
  postgres: ^2.7.0
```

### Verbindungs-Beispiel

```dart
import 'package:postgres/postgres.dart';

final connection = PostgreSQLConnection(
  'central_postgres', // oder IP-Adresse
  5432,
  'manga_inventory',
  username: 'manga_admin',
  password: 'manga_secure_2025',
);

await connection.open();

// Abfrage
final results = await connection.query(
  'SELECT * FROM manga ORDER BY created_at DESC LIMIT 20'
);

await connection.close();
```

### Alternative: Supabase Flutter SDK

Da du bereits Supabase nutzt, kannst du auch den Supabase Flutter Client verwenden:

```yaml
dependencies:
  supabase_flutter: ^1.10.0
```

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);

final supabase = Supabase.instance.client;

// Oder direkt mit PostgreSQL (empfohlen für Homelab)
```

## Backup & Maintenance

### Manueller Backup

```bash
# Dump erstellen
docker exec central_postgres pg_dump -U manga_admin manga_inventory > manga_backup_$(date +%Y%m%d).sql

# Backup wiederherstellen
docker exec -i central_postgres psql -U manga_admin -d manga_inventory < manga_backup_YYYYMMDD.sql
```

### Automatischer Backup (via Docker Volume)

Die Datenbank-Daten sind persistent in:
```
/srv/infra/data/postgres/
```

Backups können auch in:
```
/srv/infra/data/backups/
```

gespeichert werden (bereits im Docker Volume gemounted).

## Nützliche SQL-Queries

### Statistiken abrufen

```sql
SELECT
    COUNT(*) as total,
    COUNT(CASE WHEN read = true THEN 1 END) as gelesen,
    COUNT(CASE WHEN double = true THEN 1 END) as duplikate,
    COUNT(CASE WHEN newbuy = true THEN 1 END) as kaufen
FROM manga;
```

### Top 10 Autoren

```sql
SELECT autor, COUNT(*) as anzahl
FROM manga
WHERE autor IS NOT NULL
GROUP BY autor
ORDER BY anzahl DESC
LIMIT 10;
```

### Genres

```sql
SELECT genre, COUNT(*) as anzahl
FROM manga
WHERE genre IS NOT NULL
GROUP BY genre
ORDER BY anzahl DESC;
```

### Suche

```sql
SELECT titel, band, autor
FROM manga
WHERE titel ILIKE '%tokyo%'
   OR autor ILIKE '%tokyo%'
ORDER BY titel;
```

## Pgweb Web-UI

Du hast bereits pgweb in deinem Docker-Setup:

```yaml
PGWEB_DATABASE_URL: postgres://admin:ciscoroot@postgres:5432/postgres?sslmode=disable
```

Zugriff über:
- Container: `pgweb`
- Port: 8081 (wenn exposed)

Um Manga-Datenbank zu sehen, verbinde mit:
```
postgres://manga_admin:manga_secure_2025@postgres:5432/manga_inventory?sslmode=disable
```

## Nächste Schritte

1. **Flutter App Setup**
   - PostgreSQL-Client integrieren
   - Oder Supabase Flutter SDK verwenden
   - Verbindung testen

2. **API-Layer** (Optional)
   - REST API mit Dart backend (shelf, alfred)
   - Oder GraphQL (hasura, graphql_flutter)
   - Oder direkt PostgreSQL-Zugriff

3. **Backup-Strategie**
   - Automatisierte Backups einrichten
   - Cron-Job für tägliche Dumps
   - Oder Supabase als Backup-Sync nutzen

4. **Migration abschließen**
   - Next.js-App auf PostgreSQL umstellen
   - Oder parallel betreiben (Supabase + Homelab)
