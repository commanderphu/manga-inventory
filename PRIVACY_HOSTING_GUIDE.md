# Datenschutzerklärung Hosting Guide

Dieser Guide erklärt, wie du die Datenschutzerklärung für deine Manga Sammlung App online verfügbar machst.

## 📋 Was wurde erstellt?

1. **PRIVACY_POLICY_DE.md** - Deutsche Datenschutzerklärung (Markdown)
2. **PRIVACY_POLICY_EN.md** - Englische Datenschutzerklärung (Markdown)
3. **privacy-policy.html** - HTML-Version für Web-Hosting

## 🚀 Hosting-Optionen

### Option 1: GitHub Pages (Empfohlen - Kostenlos)

**Vorteile:**
- Komplett kostenlos
- Automatische HTTPS
- Einfaches Deployment
- Direkt aus deinem Repository

**Anleitung:**

1. **Repository Settings öffnen:**
   ```
   GitHub Repository → Settings → Pages
   ```

2. **Source konfigurieren:**
   - Branch: `main`
   - Folder: `/ (root)` oder `/docs`

3. **Datei hochladen:**
   ```bash
   git add privacy-policy.html PRIVACY_POLICY_DE.md PRIVACY_POLICY_EN.md
   git commit -m "Add privacy policy"
   git push
   ```

4. **URL abrufen:**
   ```
   https://commanderphu.github.io/manga-inventory/privacy-policy.html
   ```

5. **Custom Domain (optional):**
   - Du kannst eine eigene Domain verwenden (z.B. privacy.phudevelopement.xyz)

---

### Option 2: Bestehende Website/Domain

Falls du bereits eine Website hast (z.B. phudevelopement.xyz):

**Anleitung:**

1. **HTML-Datei hochladen:**
   ```bash
   # Via FTP/SFTP
   scp privacy-policy.html user@your-server.com:/var/www/html/manga-app/
   ```

2. **URL:**
   ```
   https://phudevelopement.xyz/manga-app/privacy-policy.html
   ```

---

### Option 3: Netlify (Kostenlos, sehr einfach)

**Vorteile:**
- Drag & Drop Deployment
- Automatische HTTPS
- Schnelles CDN

**Anleitung:**

1. Gehe zu https://netlify.com
2. Registriere dich (kostenlos)
3. "Add new site" → "Deploy manually"
4. Ziehe die `privacy-policy.html` in den Upload-Bereich
5. Netlify generiert eine URL wie: `https://manga-sammlung-privacy.netlify.app`

---

### Option 4: Vercel (Kostenlos)

**Anleitung:**

1. Gehe zu https://vercel.com
2. "Import Git Repository" oder "Deploy manually"
3. HTML-Datei hochladen
4. URL: `https://manga-sammlung-privacy.vercel.app`

---

### Option 5: Direkt im bestehenden API-Server

Da du bereits `manga-api.phudevelopement.xyz` hast:

**Anleitung:**

1. **Datei auf Server kopieren:**
   ```bash
   scp privacy-policy.html user@manga-api-server:/path/to/public/
   ```

2. **Express Route hinzufügen (api/src/index.js):**
   ```javascript
   app.get('/privacy-policy', (req, res) => {
     res.sendFile(path.join(__dirname, 'public', 'privacy-policy.html'));
   });
   ```

3. **URL:**
   ```
   https://manga-api.phudevelopement.xyz/privacy-policy
   ```

---

## 📝 Anpassungen vor dem Veröffentlichen

Bearbeite folgende Platzhalter in allen Dateien:

### 1. E-Mail-Adresse
```
[Ihre E-Mail-Adresse einfügen]
→ z.B.: joshua@phudevelopement.xyz
```

### 2. Server-Standort
```
[Serverstandort einfügen, z.B. Deutschland/EU]
→ z.B.: Deutschland (Frankfurt)
```

### 3. Hosting-Provider
```
[Name des Hosting-Anbieters einfügen]
→ z.B.: Hetzner, AWS, DigitalOcean
```

### 4. Datenschutzbehörde
```
[Ihre zuständige Datenschutzbehörde]
→ Abhängig von deinem Wohnort in Deutschland
```

**Beispiele:**
- NRW: https://www.ldi.nrw.de
- Bayern: https://www.datenschutz-bayern.de
- Berlin: https://www.datenschutz-berlin.de

### 5. URL in App eintragen

Nachdem die Datenschutzerklärung online ist:

**Google Play Console:**
```
App-Inhalt → Datenschutzrichtlinie
→ URL eintragen: https://[DEINE-URL]/privacy-policy.html
```

**In der App (settings_screen.dart):**
```dart
// Link zur Datenschutzerklärung hinzufügen
ListTile(
  title: Text('Datenschutzerklärung'),
  trailing: Icon(Icons.open_in_new),
  onTap: () async {
    const url = 'https://[DEINE-URL]/privacy-policy.html';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  },
)
```

---

## ✅ Checkliste

- [ ] E-Mail-Adresse in allen 3 Dateien eingefügt
- [ ] Server-Standort angegeben
- [ ] Hosting-Provider eingetragen
- [ ] Datenschutzbehörde ausgewählt
- [ ] HTML-Datei hochgeladen
- [ ] URL getestet (öffnet sich im Browser)
- [ ] URL in Google Play Console eingetragen
- [ ] Link in App-Settings hinzugefügt

---

## 🔍 Google Play Store Anforderungen

Google prüft folgende Punkte:

1. **URL muss öffentlich erreichbar sein** (keine Login-Walls)
2. **HTTPS ist Pflicht** (alle oben genannten Optionen haben HTTPS)
3. **Inhalt muss zur App passen**
4. **Sprache sollte zur App-Sprache passen** (Deutsch empfohlen)

---

## 📞 Support

Bei Fragen zur Datenschutzerklärung:
- Nutzer sollten dich per E-Mail kontaktieren können
- Antworte innerhalb von 30 Tagen auf Auskunftsersuchen (DSGVO-Pflicht)

---

## 📅 Aktualisierungen

Bei App-Updates, die neue Datenverarbeitungen betreffen:

1. Datenschutzerklärung aktualisieren
2. Version-Nummer erhöhen
3. "Letzte Aktualisierung" ändern
4. Nutzer per Push-Benachrichtigung informieren (bei wesentlichen Änderungen)

---

## 🎯 Empfehlung

Für den schnellsten Start empfehle ich **Option 1 (GitHub Pages)**:

```bash
# Quick Start
cd /path/to/manga-inventory
git add privacy-policy.html PRIVACY_POLICY_*.md
git commit -m "Add privacy policy"
git push

# Dann in GitHub: Settings → Pages → Enable
# URL: https://commanderphu.github.io/manga-inventory/privacy-policy.html
```

Diese URL trägst du dann in den Google Play Store ein.
