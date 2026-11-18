# 🚀 Manga Inventory - Deployment Guide

Vollständige Anleitung zum Deployment der Manga Inventory App mit API und Flutter.

---

## Architektur-Übersicht

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  Flutter App (Handy deiner Freundin)                       │
│  📱 manga_flutter_app                                       │
│                                                             │
└────────────────┬────────────────────────────────────────────┘
                 │ HTTPS + API-Key
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  Internet (Cloudflare Tunnel)                               │
│  🌐 manga-api.phudevelopement.xyz                           │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  Homelab Infra (/srv/infra)                                 │
│                                                             │
│  ┌────────────┐    ┌──────────────┐    ┌────────────────┐  │
│  │   Caddy    │───▶│  Manga API   │───▶│  PostgreSQL    │  │
│  │ (Reverse   │    │  (Node.js/   │    │  (central_     │  │
│  │  Proxy)    │    │   Express)   │    │   postgres)    │  │
│  └────────────┘    └──────────────┘    └────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Teil 1: API Deployment

### 1.1 API starten

```bash
cd /srv/infra
docker-compose up -d manga-api
```

### 1.2 Logs überprüfen

```bash
docker logs -f manga_api
```

Erwartete Ausgabe:
```
╔═══════════════════════════════════════════╗
║   🎌 Manga Inventory API Server          ║
╠═══════════════════════════════════════════╣
║   Port:        3000                        ║
║   Environment: production                  ║
║   Status:      Running                     ║
╚═══════════════════════════════════════════╝
✅ Connected to PostgreSQL database
```

### 1.3 Health Check

```bash
# Intern
curl https://manga-api.intern.phudevelopement.xyz/health

# Extern (falls Cloudflare Tunnel läuft)
curl https://manga-api.phudevelopement.xyz/health
```

Erwartete Antwort:
```json
{
  "status": "OK",
  "timestamp": "2025-12-31T00:00:00.000Z",
  "uptime": 123.45
}
```

### 1.4 API testen

```bash
# Manga-Liste abrufen
curl -H "X-API-Key: NTfvGXfVZf3MEgyr56qQbk5Y3Zxfj6A/kI68GnD97hs=" \
  https://manga-api.phudevelopement.xyz/api/manga | jq

# Statistiken
curl -H "X-API-Key: NTfvGXfVZf3MEgyr56qQbk5Y3Zxfj6A/kI68GnD97hs=" \
  https://manga-api.phudevelopement.xyz/api/manga/stats/summary | jq
```

### 1.5 Caddy neuladen

```bash
cd /srv/infra
docker-compose restart caddy
```

Überprüfe, dass Caddy die neuen Routen erkannt hat:
```bash
docker logs caddy_reverse_proxy | grep manga-api
```

---

## Teil 2: Flutter-App Setup

### 2.1 Voraussetzungen

Auf dem Entwicklungsrechner:

```bash
# Flutter installieren (falls noch nicht vorhanden)
# https://docs.flutter.dev/get-started/install

flutter --version
```

### 2.2 Projekt initialisieren

```bash
cd /mnt/data/docs/Dokumente/Projekts/PhuDev/manga-inventory-38/manga_flutter_app

# Dependencies installieren
flutter pub get

# Code generieren (für JSON-Serialisierung)
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2.3 App auf Handy testen (Development)

#### Android

```bash
# Android-Gerät via USB verbinden
flutter devices

# App starten
flutter run
```

#### iOS (nur auf macOS)

```bash
flutter run
```

### 2.4 Release-Build erstellen

#### Android APK

```bash
flutter build apk --release
```

APK wird erstellt in:
```
build/app/outputs/flutter-apk/app-release.apk
```

#### Android App Bundle (für Google Play)

```bash
flutter build appbundle --release
```

AAB wird erstellt in:
```
build/app/outputs/bundle/release/app-release.aab
```

### 2.5 APK an deine Freundin senden

```bash
# APK via ADB installieren
adb install build/app/outputs/flutter-apk/app-release.apk

# Oder APK-Datei per WhatsApp/E-Mail senden
cp build/app/outputs/flutter-apk/app-release.apk ~/Downloads/manga-app.apk
```

**Wichtig:** Sie muss auf ihrem Handy "Installation aus unbekannten Quellen" erlauben.

---

## Teil 3: Cloudflare Tunnel Konfiguration

### 3.1 Tunnel-Konfiguration überprüfen

Stelle sicher, dass `manga-api.phudevelopement.xyz` in deinem Cloudflare Tunnel eingerichtet ist.

### 3.2 DNS-Einträge

In Cloudflare Dashboard:

1. Gehe zu **DNS** → **Records**
2. Füge einen CNAME-Eintrag hinzu:

```
Type: CNAME
Name: manga-api
Target: <dein-tunnel-id>.cfargotunnel.com
Proxied: ON
```

### 3.3 Tunnel testen

```bash
# Von außerhalb deines Netzwerks (z.B. Handy mit mobilen Daten)
curl https://manga-api.phudevelopement.xyz/health
```

---

## Teil 4: Sicherheit & Best Practices

### 4.1 API-Key sichern

Der API-Key ist in der Flutter-App hardcoded. Das ist für private Apps OK, aber beachte:

- ✅ Verwende den API-Key NUR in dieser App
- ✅ Teile den Key NIEMALS öffentlich
- ✅ Ändere den Key, falls kompromittiert:

```bash
# Neuen Key generieren
openssl rand -base64 32

# In /srv/infra/.env aktualisieren
nano /srv/infra/.env
# MANGA_API_KEY=<neuer-key>

# API neu starten
docker-compose restart manga-api
```

### 4.2 Rate Limiting

Die API limitiert Requests auf:
- 100 Requests pro 15 Minuten

Für deine Freundin ist das mehr als genug.

### 4.3 HTTPS

- ✅ Alle Verbindungen sind verschlüsselt (HTTPS)
- ✅ Caddy generiert automatisch SSL-Zertifikate
- ✅ API ist NUR über HTTPS erreichbar

---

## Teil 5: Monitoring & Wartung

### 5.1 API-Logs anzeigen

```bash
# Live-Logs
docker logs -f manga_api

# Letzte 100 Zeilen
docker logs --tail 100 manga_api

# Caddy-Logs (Access-Log)
tail -f /srv/infra/data/caddy_config/logs/manga-api.access.log
```

### 5.2 Datenbank-Backup

```bash
# Manuelles Backup
docker exec central_postgres pg_dump -U manga_admin manga_inventory > \
  /srv/infra/data/backups/manga_$(date +%Y%m%d_%H%M%S).sql

# Automatisches Backup (Cron)
crontab -e

# Füge hinzu (täglich um 3 Uhr morgens):
0 3 * * * docker exec central_postgres pg_dump -U manga_admin manga_inventory > /srv/infra/data/backups/manga_$(date +\%Y\%m\%d).sql
```

### 5.3 API neu starten

```bash
cd /srv/infra
docker-compose restart manga-api
```

### 5.4 Updates einspielen

```bash
# API-Code aktualisieren
cd /mnt/data/docs/Dokumente/Projekts/PhuDev/manga-inventory-38/manga-api
# ... Änderungen machen ...

# Docker-Image neu bauen und starten
cd /srv/infra
docker-compose up -d --build manga-api
```

---

## Teil 6: Troubleshooting

### Problem: API nicht erreichbar

```bash
# 1. Ist der Container running?
docker ps | grep manga_api

# 2. Logs überprüfen
docker logs manga_api

# 3. Datenbank-Verbindung testen
docker exec manga_api node -e "
const { Pool } = require('pg');
const pool = new Pool({
  host: 'central_postgres',
  port: 5432,
  database: 'manga_inventory',
  user: 'manga_admin',
  password: '<DB_PASSWORD>'
});
pool.query('SELECT COUNT(*) FROM manga').then(r => console.log(r.rows[0]));
"

# 4. Caddy-Konfiguration überprüfen
docker exec caddy_reverse_proxy caddy validate --config /etc/caddy/Caddyfile
```

### Problem: Flutter-App kann API nicht erreichen

```bash
# 1. Internet-Verbindung des Handys prüfen
# 2. DNS-Auflösung testen
nslookup manga-api.phudevelopement.xyz

# 3. API-Erreichbarkeit von extern testen
curl https://manga-api.phudevelopement.xyz/health

# 4. API-Key in Flutter-App überprüfen
# lib/services/manga_api_service.dart:3
```

### Problem: "Unauthorized" Fehler

Der API-Key ist falsch oder fehlt. Überprüfe:

1. Key in Flutter-App: `lib/services/manga_api_service.dart`
2. Key in API: `/srv/infra/.env` → `MANGA_API_KEY`

Beide müssen identisch sein.

---

## Teil 7: Features erweitern

### Neue Features hinzufügen

1. **API erweitern** (`manga-api/src/routes/manga.js`)
2. **Flutter-Service aktualisieren** (`lib/services/manga_api_service.dart`)
3. **UI anpassen** (`lib/screens/`)
4. **API neu deployen**:
   ```bash
   cd /srv/infra
   docker-compose up -d --build manga-api
   ```
5. **Flutter-App neu bauen**:
   ```bash
   flutter build apk --release
   ```

---

## Zusammenfassung

**API:**
- ✅ Läuft in Docker unter `/srv/infra`
- ✅ Erreichbar unter `https://manga-api.phudevelopement.xyz`
- ✅ Gesichert mit API-Key-Authentifizierung
- ✅ Verbunden mit PostgreSQL (`manga_inventory`)

**Flutter-App:**
- ✅ Kommuniziert via HTTPS mit API
- ✅ Zeigt Manga-Sammlung an
- ✅ Kann Status ändern (gelesen, etc.)
- ✅ Kann Manga löschen
- ✅ Läuft auf Android (und iOS)

**Datenbank:**
- ✅ PostgreSQL in Docker
- ✅ 138 Manga-Einträge
- ✅ Automatische Backups möglich

**Nächste Schritte:**
1. API deployen: `docker-compose up -d manga-api`
2. Flutter-App bauen: `flutter build apk --release`
3. APK an Freundin senden
4. App installieren und testen
5. Features erweitern nach Bedarf

---

**Wichtige Links:**

- API-Dokumentation: `manga-api/README.md`
- Datenbank-Setup: `DATABASE-SETUP.md`
- Flutter-App: `manga_flutter_app/`
