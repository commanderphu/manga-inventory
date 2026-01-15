# 📚 Manga Inventory System

Ein vollständiges Verwaltungssystem für deine persönliche Manga-Sammlung mit Web-Frontend, REST-API und Mobile App.

[![Next.js](https://img.shields.io/badge/Next.js-15.2-black?style=for-the-badge&logo=next.js)](https://nextjs.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev/)
[![Node.js](https://img.shields.io/badge/Node.js-Express-339933?style=for-the-badge&logo=node.js)](https://nodejs.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791?style=for-the-badge&logo=postgresql)](https://www.postgresql.org/)

---

## 📝 Übersicht

Manga Inventory ist ein Multi-Plattform System zur Verwaltung deiner Manga-Sammlung. Das Projekt besteht aus drei Hauptkomponenten:

- **Web-Frontend**: Moderne Next.js-Anwendung für Desktop und Tablet
- **REST-API**: Sichere Node.js/Express-API mit PostgreSQL-Datenbank
- **Mobile App**: Native Flutter-App für iOS und Android mit Barcode-Scanner

> Die Idee entstand aus dem Wunsch, eine analoge Excel-Manga-Liste digital, durchsuchbar und mobil zugänglich zu machen – inklusive Cover-Anzeige, ISBN-Scanner und Statistiken.

---

## 🏗️ Architektur

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Web Frontend   │     │   Mobile App    │     │   REST API      │
│   (Next.js)     │────▶│   (Flutter)     │────▶│  (Node.js)      │
│                 │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └────────┬────────┘
                                                          │
                                                          ▼
                                                  ┌─────────────────┐
                                                  │   PostgreSQL    │
                                                  │    Database     │
                                                  └─────────────────┘
```

---

## 🚀 Komponenten

### Frontend (`/frontend`)

Next.js 15 Web-Anwendung mit modernem UI

**Tech Stack:**
- Next.js 15.2 mit React 19
- TypeScript
- TailwindCSS + shadcn/ui
- Supabase Client
- Excel-Import (xlsx)
- Barcode-Scanner (@zxing)

**Features:**
- Manga-Verwaltung (CRUD)
- Erweiterte Such- und Filterfunktionen
- Excel-Import/-Export
- ISBN-Scanner (Webcam)
- Statistiken und Dashboards
- Dark Mode Support

**Setup:**
```bash
cd frontend
pnpm install
cp .env.local.example .env.local
# .env.local mit Supabase-Credentials befüllen
pnpm dev
```

### API (`/api`)

Node.js/Express REST-API mit JWT-Authentifizierung

**Tech Stack:**
- Express.js
- PostgreSQL (pg)
- JWT Authentication
- Helmet (Security)
- Rate Limiting
- Morgan (Logging)

**Features:**
- RESTful Endpoints für Manga-Verwaltung
- API-Key Authentifizierung
- Rate Limiting (100 req/15min)
- CORS-Support
- Health-Checks

**Setup:**
```bash
cd api
npm install
cp .env.example .env
# .env mit Datenbank-Credentials befüllen
npm start
```

**API-Dokumentation:** Siehe [api/README.md](api/README.md)

### Mobile App (`/app`)

Flutter-App für iOS und Android

**Tech Stack:**
- Flutter 3.0+
- Riverpod (State Management)
- Firebase (Push-Notifications)
- Mobile Scanner (Barcode)
- Cached Network Images
- HTTP Client

**Features:**
- Native Performance
- ISBN Barcode-Scanner
- Offline-Support (geplant)
- Push-Benachrichtigungen
- Bildupload für Cover

**Setup:**
```bash
cd app
flutter pub get
flutter run
```

---

## 🗄️ Datenbank

PostgreSQL-Datenbank mit 138+ Manga-Einträgen

**Schema:**
- UUID Primary Keys
- Volltext-Suche
- Automatische Timestamps
- Indizes für Performance

**Felder:**
- Titel, Band, Autor, Genre
- ISBN, Verlag, Sprache
- Status (gelesen, doppelt, neu kaufen)
- Cover-Image URL
- Timestamps (created_at, updated_at)

**Setup-Anleitung:** Siehe [docs/DATABASE-SETUP.md](docs/DATABASE-SETUP.md)

---

## 🎯 Features

### Verwaltung
- Manga hinzufügen, bearbeiten, löschen
- Bulk-Operationen
- ISBN-basierte Suche
- Cover-Import

### Suche & Filter
- Volltextsuche
- Filter nach Genre, Autor, Verlag
- Status-Filter (gelesen, doppelt, etc.)
- Sortierung nach verschiedenen Feldern

### Import/Export
- Excel-Import (.xlsx)
- Datenexport
- Cover-Finder Script

### Statistiken
- Gesamtanzahl Manga
- Gelesene/Ungelesene
- Duplikate
- Genre-Verteilung
- Top-Autoren

---

## 🛠️ Tech Stack

**Frontend:**
- Next.js 15.2 (App Router)
- React 19
- TypeScript
- TailwindCSS
- Radix UI (via shadcn/ui)
- Zod (Validation)
- React Hook Form
- date-fns

**Backend:**
- Node.js
- Express
- PostgreSQL
- JWT (jsonwebtoken)
- bcrypt
- Helmet
- CORS

**Mobile:**
- Flutter 3.0+
- Dart
- Riverpod
- Firebase Core & Messaging
- JSON Serialization
- Mobile Scanner

**Infrastruktur:**
- Docker
- Caddy (Reverse Proxy)
- Cloudflare Tunnel
- PostgreSQL in Docker

---

## 📦 Installation

### Voraussetzungen

- Node.js 18+
- Flutter 3.0+ (für Mobile App)
- PostgreSQL 14+
- pnpm (empfohlen für Frontend)

### Schnellstart

1. **Repository klonen:**
   ```bash
   git clone https://github.com/commanderphu/manga-inventory.git
   cd manga-inventory
   ```

2. **Datenbank einrichten:**
   ```bash
   # PostgreSQL-Datenbank erstellen
   cd scripts/database
   psql -U postgres -f setup-postgres-manga.sql
   ```

3. **API starten:**
   ```bash
   cd api
   npm install
   cp .env.example .env
   # .env konfigurieren
   npm start
   ```

4. **Frontend starten:**
   ```bash
   cd frontend
   pnpm install
   cp .env.local.example .env.local
   # .env.local konfigurieren
   pnpm dev
   ```

5. **Mobile App (optional):**
   ```bash
   cd app
   flutter pub get
   flutter run
   ```

---

## 📖 Dokumentation

- [API-Dokumentation](api/README.md)
- [Datenbank-Setup](docs/DATABASE-SETUP.md)
- [Deployment-Guide](docs/DEPLOYMENT-GUIDE.md)
- [Flutter-App](app/README.md)

---

## 🚢 Deployment

### Production Setup

Das System kann über Docker deployed werden:

1. **API**: Docker-Container mit Express-Server
2. **Frontend**: Vercel/Static Hosting
3. **Datenbank**: PostgreSQL in Docker
4. **Reverse Proxy**: Caddy mit HTTPS

Detaillierte Anleitung: [docs/DEPLOYMENT-GUIDE.md](docs/DEPLOYMENT-GUIDE.md)

### Cloudflare Tunnel

Für externen Zugriff kann ein Cloudflare Tunnel eingerichtet werden:
```
manga-api.phudevelopement.xyz → API
```

---

## 🔧 Entwicklung

### Verzeichnisstruktur

```
manga-inventory/
├── frontend/          # Next.js Web-App
│   ├── app/          # App Router Pages
│   ├── components/   # React Components
│   ├── lib/          # Utils & API Client
│   └── public/       # Static Assets
├── api/              # Node.js REST-API
│   ├── src/          # Source Code
│   ├── config/       # Configuration
│   └── migrations/   # DB-Migrations
├── app/              # Flutter Mobile App
│   ├── lib/          # Dart Source
│   ├── android/      # Android Config
│   └── ios/          # iOS Config
├── scripts/          # Helper Scripts
│   ├── database/     # DB-Tools
│   └── cover-finder/ # Cover-Import
└── docs/             # Dokumentation
```

### Excel-Import

Im Ordner `frontend/public` gibt es eine Beispieldatei:
1. `manga-list.xlsx.example` kopieren
2. In `manga-list.xlsx` umbenennen
3. Manga-Sammlung eintragen
4. Über Web-UI hochladen

### Scripts

**Datenbank-Tools** (`scripts/database/`):
- `create-sqlite-db.js` - SQLite-Datenbank erstellen
- `export-db.js` - Datenbank exportieren
- `export-supabase-to-postgres.js` - Supabase zu PostgreSQL migrieren
- `setup-postgres-manga.sql` - PostgreSQL-Setup

**Cover-Finder** (`scripts/cover-finder/`):
- Automatische Cover-Suche via ISBN
- Integration mit Cover-APIs

---

## 🔐 Sicherheit

- API-Key Authentifizierung
- Rate Limiting (100 Requests/15min)
- Helmet.js für HTTP-Security-Headers
- CORS-Konfiguration
- HTTPS-Only (via Caddy)
- JWT für Mobile App (geplant)

---

## 🤝 Contributing

Contributions sind willkommen! Bitte erstelle einen Pull Request oder Issue.

---

## 📝 Lizenz

MIT License

---

## 📬 Kontakt

**Joshua (commanderphu)**
[LinkedIn](https://www.linkedin.com/in/joshuaphu/) · [GitHub](https://github.com/commanderphu)

---

## 🙏 Danksagungen

- shadcn/ui für die UI-Komponenten
- Supabase für die Backend-Services
- Vercel für das Hosting
- Flutter Community
