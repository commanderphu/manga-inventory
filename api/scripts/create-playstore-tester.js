#!/usr/bin/env node

const https = require('https');

const API_KEY = process.env.API_KEY;
const HOST = 'manga-api.phudevelopement.xyz';

if (!API_KEY) {
  console.error('Bitte API_KEY setzen: API_KEY=xxx node scripts/create-playstore-tester.js');
  process.exit(1);
}

const body = JSON.stringify({
  email: 'playstore.test@phuonline.de',
  name: 'Play Store Tester',
  password: 'TestManga2026!',
});

const options = {
  hostname: HOST,
  path: '/api/auth/register',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-API-Key': API_KEY,
    'Content-Length': Buffer.byteLength(body),
  },
};

const req = https.request(options, (res) => {
  let data = '';
  res.on('data', (chunk) => (data += chunk));
  res.on('end', () => {
    const result = JSON.parse(data);
    if (res.statusCode === 201) {
      console.log('Test-Account angelegt:');
      console.log('  E-Mail:    playstore.test@phuonline.de');
      console.log('  Passwort:  TestManga2026!');
    } else if (res.statusCode === 409) {
      console.log('Account existiert bereits — alles gut.');
    } else {
      console.error('Fehler:', res.statusCode, result);
    }
  });
});

req.on('error', (e) => console.error('Verbindungsfehler:', e.message));
req.write(body);
req.end();
