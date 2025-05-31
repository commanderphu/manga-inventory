const express = require('express');
const router = express.Router();
const db = require('../db/database') // Assuming you have a db.js file for database operations

// Alle Mangas abrufen
router.get('/', (req, res) => {
    const rows = db.prepare('SELECT * FROM mangas order by title, band').all();
    const manags = rows.map(row => ({
        ...m,
        read: !!m.read,
        new_buy:  !!m.new_buy,
        double: !!m.double
    }));
    res.json(mangas);
});

// Einen Manga anlegen 

router.post('/', (req, res) => {
    const {  titel, band, genre, autor, verlag, isbn, sprache, cover_url, read, new_buy , double  } = req.body;
   if (!titel || !band) {
        return res.status(400).json({ error: 'Titel und Band sind erforderlich.' });
    }
    const result = db.prepare('INSERT INTO mangas (titel, band, genre, autor, verlag, isbn, sprache, cover_url, read, new_buy, double) VALUES (?, ?, ?, ?, ?, ?, ?, ?,?,?,?)')
        .run(titel, band, genre, autor, verlag, isbn, sprache, cover_url, read, new_buy, double);
    const insertedManga = db.prepare('SELECT * FROM mangas WHERE id = ?').get(result.lastInsertRowid);
    res.status(201).json(insertedManga);

});

// Einen Manga aktualisieren

router.put('/:id', (req, res) => {
    const { id } = req.params;
    const { titel, band, genre, autor, verlag, isbn, sprache, cover_url, read, new_buy, double } = req.body;

    if (!titel || !band) {
        return res.status(400).json({ error: 'Titel und Band sind erforderlich.' });
    }

    const result = db.prepare('UPDATE mangas SET titel = ?, band = ?, genre = ?, autor = ?, verlag = ?, isbn = ?, sprache = ?, cover_url = ?,read = ?, new_buy = ?, double = ? WHERE id = ?')
        .run(titel, band, genre, autor, verlag, isbn, sprache, cover_url, id,read, new_buy, double);

    if (result.changes === 0) {
        return res.status(404).json({ error: 'Manga nicht gefunden.' });
    }

    const updatedManga = db.prepare('SELECT * FROM mangas WHERE id = ?').get(id);
    res.json(updatedManga);
});
// Einen Manga löschen

router.delete('/:id', (req, res) => {
    const { id } = req.params;

    const result = db.prepare('DELETE FROM mangas WHERE id = ?').run(id);

    if (result.changes === 0) {
        return res.status(404).json({ error: 'Manga nicht gefunden.' });
    }

    res.status(204).send(); // No content
});

// Einen Manga nach ID abrufen
router.get('/:id', (req, res) => {
    const { id } = req.params;
    const manga = db.prepare('SELECT * FROM mangas WHERE id = ?').get(id);

    if (!manga) {
        return res.status(404).json({ error: 'Manga nicht gefunden.' });
    }

    res.json(manga);
});
// Einen Manga nach Titel und Band abrufen
router.get('/search', (req, res) => {
    const { titel, band } = req.query;

    if (!titel || !band) {
        return res.status(400).json({ error: 'Titel und Band sind erforderlich.' });
    }

    const manga = db.prepare('SELECT * FROM mangas WHERE titel = ? AND band = ?').get(titel, band);

    if (!manga) {
        return res.status(404).json({ error: 'Manga nicht gefunden.' });
    }

    res.json(manga);
});
module.exports = router;
