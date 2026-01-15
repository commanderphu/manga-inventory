# Datenschutzerklärung für Manga Sammlung

**Stand:** 15. Januar 2026
**Version:** 1.0

## 1. Verantwortlicher

PhuDevelopment
Joshua Phu Kuhrau
E-Mail: joshua@phuonline.de

## 2. Allgemeines

Der Schutz Ihrer persönlichen Daten ist uns ein wichtiges Anliegen. Diese Datenschutzerklärung informiert Sie darüber, welche Daten wir in der App "Manga Sammlung" erheben, zu welchem Zweck und wie wir diese verarbeiten.

Die Nutzung unserer App ist mit der Verarbeitung personenbezogener Daten verbunden. Diese Datenschutzerklärung klärt Sie gemäß der Datenschutz-Grundverordnung (DSGVO) über Art, Umfang und Zweck der Verarbeitung personenbezogener Daten auf.

## 3. Erhobene Daten

### 3.1 Account-Daten

Zur Nutzung der App ist eine Registrierung erforderlich. Dabei erheben wir:

- **E-Mail-Adresse** (Pflichtfeld)
- **Name** (Pflichtfeld)
- **Passwort** (verschlüsselt gespeichert)

**Rechtsgrundlage:** Art. 6 Abs. 1 lit. b DSGVO (Vertragserfüllung)
**Zweck:** Erstellung und Verwaltung Ihres Benutzerkontos, Authentifizierung

### 3.2 Manga-Sammlungsdaten

Im Rahmen der Nutzung der App speichern wir folgende Daten zu Ihrer Manga-Sammlung:

- Manga-Titel und Bandnummer
- Autor, Genre, Verlag
- ISBN-Nummer
- Sprache
- Lese-Status (gelesen, ungelesen, doppelt, neu kaufen)
- Cover-Bild-URLs
- Notizen und Bewertungen
- Zeitstempel (Erstellungs- und Änderungsdatum)

**Rechtsgrundlage:** Art. 6 Abs. 1 lit. b DSGVO (Vertragserfüllung)
**Zweck:** Bereitstellung der Kernfunktionalität der App (Verwaltung Ihrer Manga-Sammlung)

### 3.3 Technische Daten

Bei der Nutzung der App werden automatisch folgende technische Daten erhoben:

- IP-Adresse (temporär für API-Anfragen)
- Gerätetyp und Betriebssystemversion
- App-Version
- Zeitstempel von API-Anfragen
- Fehlerprotokolle (Crash-Logs)

**Rechtsgrundlage:** Art. 6 Abs. 1 lit. f DSGVO (berechtigtes Interesse)
**Zweck:** Sicherstellung der technischen Funktionalität, Fehleranalyse, Sicherheit

### 3.4 Firebase Push-Benachrichtigungen

Für Push-Benachrichtigungen nutzen wir Firebase Cloud Messaging (Google). Dabei werden folgende Daten verarbeitet:

- Firebase Device Token
- Zeitstempel der Benachrichtigungen
- Zustellungsstatus

**Rechtsgrundlage:** Art. 6 Abs. 1 lit. a DSGVO (Einwilligung)
**Zweck:** Versand von Benachrichtigungen über neue Manga-Releases oder App-Updates

Sie können Push-Benachrichtigungen jederzeit in den Geräteeinstellungen deaktivieren.

## 4. Kamerazugriff

Die App benötigt Zugriff auf Ihre Kamera ausschließlich für die ISBN-Scanner-Funktion. Die aufgenommenen Bilder werden:

- **NICHT gespeichert**
- **NICHT an Server übertragen**
- Nur temporär im Arbeitsspeicher zur Barcode-Erkennung verarbeitet
- Sofort nach der Verarbeitung gelöscht

**Rechtsgrundlage:** Art. 6 Abs. 1 lit. a DSGVO (Einwilligung)
**Zweck:** Ermöglichung des ISBN-Barcode-Scannens

## 5. Datenweitergabe und Empfänger

### 5.1 Eigene Server

Ihre Daten werden auf unseren eigenen Servern (manga-api.phudevelopement.xyz) gespeichert und verarbeitet. Der Server befindet sich in Deutschland (Koblenz, Rheinland-Pfalz) und wird selbst gehostet.

### 5.2 Drittanbieter-Dienste

Wir nutzen folgende Drittanbieter-Dienste:

**Firebase (Google LLC)**
- Zweck: Push-Benachrichtigungen
- Standort: USA (mit EU-US Data Privacy Framework)
- Datenschutzerklärung: https://firebase.google.com/support/privacy

### 5.3 Keine Weitergabe an Dritte

Wir geben Ihre persönlichen Daten **nicht** an Dritte weiter, außer:
- Sie haben ausdrücklich eingewilligt (Art. 6 Abs. 1 lit. a DSGVO)
- Es besteht eine gesetzliche Verpflichtung (Art. 6 Abs. 1 lit. c DSGVO)
- Die Weitergabe ist zur Vertragsdurchführung erforderlich (Art. 6 Abs. 1 lit. b DSGVO)

## 6. Datenspeicherung und Löschung

### 6.1 Speicherdauer

- **Account-Daten:** Bis zur Löschung Ihres Accounts
- **Manga-Sammlungsdaten:** Bis zur manuellen Löschung durch Sie oder Account-Löschung
- **Technische Logs:** Maximal 30 Tage
- **Crash-Reports:** Maximal 90 Tage

### 6.2 Löschung

Sie können jederzeit:
- Einzelne Manga-Einträge löschen
- Ihren gesamten Account löschen (in den App-Einstellungen oder per E-Mail-Anfrage)

Nach Account-Löschung werden alle Ihre Daten innerhalb von 30 Tagen vollständig und unwiderruflich gelöscht.

## 7. Datensicherheit

Wir setzen technische und organisatorische Sicherheitsmaßnahmen ein, um Ihre Daten zu schützen:

- **Verschlüsselung:** HTTPS/TLS für alle Datenübertragungen
- **Passwort-Hashing:** Passwörter werden mit bcrypt verschlüsselt gespeichert
- **Sichere Token:** JWT-Tokens für Authentifizierung
- **Zugriffskontrolle:** Strenge Zugriffsbeschränkungen auf Server und Datenbank
- **Regelmäßige Updates:** Sicherheitsupdates für Server und App

## 8. Ihre Rechte (DSGVO)

Als betroffene Person haben Sie folgende Rechte:

### 8.1 Auskunftsrecht (Art. 15 DSGVO)
Sie haben das Recht, Auskunft über die von uns verarbeiteten Daten zu erhalten.

### 8.2 Recht auf Berichtigung (Art. 16 DSGVO)
Sie können die Berichtigung unrichtiger Daten verlangen.

### 8.3 Recht auf Löschung (Art. 17 DSGVO)
Sie können die Löschung Ihrer Daten verlangen ("Recht auf Vergessenwerden").

### 8.4 Recht auf Einschränkung (Art. 18 DSGVO)
Sie können die Einschränkung der Verarbeitung verlangen.

### 8.5 Recht auf Datenübertragbarkeit (Art. 20 DSGVO)
Sie können Ihre Daten in einem strukturierten, maschinenlesbaren Format erhalten.

### 8.6 Widerspruchsrecht (Art. 21 DSGVO)
Sie können der Verarbeitung Ihrer Daten widersprechen.

### 8.7 Widerruf der Einwilligung (Art. 7 Abs. 3 DSGVO)
Sie können erteilte Einwilligungen jederzeit widerrufen.

### 8.8 Beschwerderecht (Art. 77 DSGVO)
Sie können sich bei einer Datenschutz-Aufsichtsbehörde beschweren.

**Kontakt zur Ausübung Ihrer Rechte:**
E-Mail: joshua@phuonline.de

## 9. Minderjährigenschutz

Die App richtet sich an Nutzer ab 16 Jahren. Personen unter 16 Jahren dürfen die App nur mit Zustimmung eines Erziehungsberechtigten nutzen.

## 10. Keine automatisierte Entscheidungsfindung

Wir nutzen keine automatisierte Entscheidungsfindung oder Profiling gemäß Art. 22 DSGVO.

## 11. Keine Werbung oder Tracking

Wir verwenden:
- **KEINE Werbe-Tracker**
- **KEINE Analyse-Tools** (wie Google Analytics)
- **KEINE Cookies** (außer technisch notwendige)
- **KEIN Verkauf von Daten**

## 12. Änderungen dieser Datenschutzerklärung

Wir behalten uns vor, diese Datenschutzerklärung anzupassen, um sie an geänderte Rechtslage oder Funktionen der App anzupassen. Die aktuelle Version ist stets in der App und unter [URL einfügen] abrufbar.

Bei wesentlichen Änderungen werden Sie per Push-Benachrichtigung oder E-Mail informiert.

## 13. Kontakt

Bei Fragen zum Datenschutz oder zur Ausübung Ihrer Rechte kontaktieren Sie uns:

**PhuDevelopment**
Joshua Phu Kuhrau
E-Mail: joshua@phuonline.de

**Zuständige Aufsichtsbehörde:**
Der Landesbeauftragte für den Datenschutz und die Informationsfreiheit Rheinland-Pfalz
Postfach 30 40
55020 Mainz
Telefon: 06131 208-2449
E-Mail: poststelle@datenschutz.rlp.de
https://www.datenschutz.rlp.de

---

**Letzte Aktualisierung:** 15. Januar 2026
