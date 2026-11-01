# Roadmap

Stand: 01.11.2026 · Fortschritt live in den [Meilensteinen](https://github.com/commanderphu/manga-inventory/milestones) und im Epic [#31](https://github.com/commanderphu/manga-inventory/issues/31).

## Vision

Manga Inventory ist ein offenes Projekt zum **Selbsthosten**, ähnlich wie paperless-ngx oder Home Assistant: Du betreibst deine eigene Instanz, im Homelab, auf einem VPS oder einem Raspberry Pi, und greifst mit der App oder im Browser darauf zu.

- **Kein zentraler Dienst.** Es gibt keinen Standard-Server. Die App verbindet sich mit der Instanz, die du ihr nennst.
- **Eine Installation = ein Haushalt.** Alle Konten einer Instanz teilen sich eine Sammlung. Das ist gewollt.
- **Offline zuerst in der App.** Die App hält die ganze Sammlung samt Covern auf dem Gerät. Sie bleibt benutzbar, wenn das Netz gedrosselt ist, kein Empfang da ist oder der Server nicht erreichbar ist. Änderungen werden nachgereicht.
- **Ein Container.** Der Server liefert API und Weboberfläche gemeinsam aus. Dazu kommt nur noch Postgres.

## Phasen

### Phase 0 · Grundlagen (App 1.1.2)

Nützt jeder Installation sofort, auch der bestehenden.

| Issue | Inhalt |
|---|---|
| [#13](https://github.com/commanderphu/manga-inventory/issues/13) | API-URL zentral statt dreimal fest im Code |
| [#35](https://github.com/commanderphu/manga-inventory/issues/35) | Offline-Modus robust: Timeouts, Server-Erreichbarkeit, Cover-Cache |
| [#26](https://github.com/commanderphu/manga-inventory/issues/26) | Registrierung per Konfiguration, Standard `closed` |
| [#11](https://github.com/commanderphu/manga-inventory/issues/11) | API bricht ohne DB-Konfiguration ab statt Standardwerte zu nutzen |
| [#12](https://github.com/commanderphu/manga-inventory/issues/12) | Migrationen nachverfolgen und beim Start ausführen |

### Phase 1 · Server frei wählbar (App 1.2)

Die App verbindet sich mit jeder Manga-Inventory-Instanz.

| Issue | Inhalt |
|---|---|
| [#23](https://github.com/commanderphu/manga-inventory/issues/23) | `GET /api/info`: Server-Erkennung, Name, Kompatibilität |
| [#24](https://github.com/commanderphu/manga-inventory/issues/24) | Server im Onboarding verbinden und in den Einstellungen wechseln |

### Phase 2 · Selbst betreiben (1.3)

Andere können eine Instanz sicher betreiben und die App installieren.

| Issue | Inhalt |
|---|---|
| [#6](https://github.com/commanderphu/manga-inventory/issues/6) | Weboberfläche mit Flutter Web statt Next.js, von der API ausgeliefert (bringt den Login ins Web) |
| [#27](https://github.com/commanderphu/manga-inventory/issues/27) | Self-Hosting-Paket: `docker compose`, `.env.example`, Doku, erstes Admin-Konto, amd64 und arm64 |
| [#28](https://github.com/commanderphu/manga-inventory/issues/28) | Push-Benachrichtigungen optional |
| [#34](https://github.com/commanderphu/manga-inventory/issues/34) | App als APK über GitHub Releases verteilen |

### Phase 3 · Bequem verbinden (1.4)

| Issue | Inhalt |
|---|---|
| [#29](https://github.com/commanderphu/manga-inventory/issues/29) | App per QR-Code aus der Weboberfläche verbinden |
| [#30](https://github.com/commanderphu/manga-inventory/issues/30) | Server im Heimnetz per mDNS finden |

## Weitere Ideen ohne feste Phase

| Issue | Inhalt |
|---|---|
| [#2](https://github.com/commanderphu/manga-inventory/issues/2), [#3](https://github.com/commanderphu/manga-inventory/issues/3) | Reihen mit Gesamtzahl der Bände, gruppierte Anzeige |
| [#4](https://github.com/commanderphu/manga-inventory/issues/4) | Favoriten und Bewertung für Reihen |
| [#5](https://github.com/commanderphu/manga-inventory/issues/5) | Dropdown für Verlag und Genre statt Freitext |
| [#25](https://github.com/commanderphu/manga-inventory/issues/25) | Getrennte Sammlungen pro Konto, nur falls eine Instanz mehrere Haushalte bedienen soll |
| [#10](https://github.com/commanderphu/manga-inventory/issues/10), [#14](https://github.com/commanderphu/manga-inventory/issues/14), [#15](https://github.com/commanderphu/manga-inventory/issues/15) | Wartung: API-Tests und Lint, Node-24-Actions, `flutter_secure_storage` 11 |

## Entscheidungen

- **Kein Standard-Server.** Jede Instanz wird selbst betrieben. Deshalb ist eine Datentrennung pro Konto (#25) keine Voraussetzung.
- **Flutter Web statt Next.js.** Eine Codebasis für App und Web, und den Login gibt es schon. Die API liefert die Oberfläche selbst aus, also ein Container, kein CORS. Das bisherige Next.js-Frontend läuft weiter, bis die Web-Version gleichwertig ist.
- **Offline ist Aufgabe der App.** Die Weboberfläche kommt vom Server und funktioniert deshalb nur online.
- **QR-Code vor mDNS.** Ein QR-Code funktioniert auch mit HTTPS und von unterwegs. mDNS geht nur im Heimnetz und ist unter Docker eingeschränkt.
- **Push nur, wenn der Server es kann.** Firebase hängt an einem Firebase-Projekt, dessen Zugangsdaten man nicht weitergeben kann. Ein zentraler Push-Relay wie bei Home Assistant wäre ein späteres Thema.
