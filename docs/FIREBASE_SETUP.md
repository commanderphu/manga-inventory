# Firebase Cloud Messaging Setup

## Status
✅ Notification System ist implementiert
⚠️ Firebase-Projekt muss noch konfiguriert werden

## Was funktioniert schon OHNE Firebase:
- ✅ Login & User Management
- ✅ Manga CRUD Operationen
- ✅ Activity Logging im Backend
- ✅ Notification Settings (Ein/Aus Toggle)
- ✅ In-App Updates (wenn App offen ist)

## Was FIREBASE BENÖTIGT:
- 🔔 **Push-Notifications wenn App geschlossen ist**

## Firebase-Projekt einrichten (10 Minuten):

### 1. Firebase Console öffnen
https://console.firebase.google.com/

### 2. Neues Projekt erstellen
- Klick auf "Projekt hinzufügen"
- Name: **Manga Inventory**
- Google Analytics: **Optional** (kann deaktiviert werden)

### 3. Android-App hinzufügen
- Klick auf das Android-Icon
- **Android-Paketname:** `com.phudevelopement.manga_flutter_app`
- App-Nickname: Manga Sammlung
- SHA-1: (optional, nicht nötig für FCM)

### 4. google-services.json herunterladen
- Download die `google-services.json` Datei
- **Ersetze** die Datei hier:
  ```
  manga_app_new/android/app/google-services.json
  ```

### 5. Server Key kopieren
- Gehe zu: **Projekteinstellungen** → **Cloud Messaging** Tab
- Kopiere den **Server key**
- Füge ihn in `/srv/infra/.env` hinzu:
  ```
  FIREBASE_SERVER_KEY=dein-server-key-hier
  ```

### 6. API starten
```bash
cd /srv/infra
docker compose restart manga-api
```

### 7. App neu bauen und deployen
```bash
cd manga_app_new
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Testen:
1. Auf Handy 1: Als Phu einloggen
2. Auf Handy 2: Als Jessi einloggen
3. Auf Handy 1: Einen Manga hinzufügen/bearbeiten
4. 🔔 Handy 2 sollte eine Push-Notification bekommen!

## Hinweis:
Die App funktioniert auch **ohne** Firebase-Setup, nur eben ohne Push-Notifications. Alle anderen Features (Login, Manga-Verwaltung, Settings) funktionieren einwandfrei!
