const axios = require('axios');
const XLSX = require('xlsx');
const db = require('./db/database'); 

async function fetchMangaData(title, volume) {
  const query =  encodeURIComponent(`${title} Band ${volume}`);
  const url ="https://www.googleapis.com/books/v1/volumes?q=" + query + "&maxResults=1&key=AIzaSyD9b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q";
  
  try {
    const response = await axios.get(url, { timeout: 1000 });
    const data = response.data;
    if (data.totalItems > 0) {
      const book = data.items[0].volumeInfo;

      let isbn = null;
      if (book.industryIdentifiers) {
        const isbn13 = book.industryIdentifiers.find(id => id.type === 'ISBN_13');
        const isbn10 = book.industryIdentifiers.find(id => id.type === 'ISBN_10');
        isbn = isbn13?.identifier || isbn10?.identifier || null;

        return {
          autor: book.authors ? book.authors.join(', ') : null,
          verlag: book.publisher || null,
          isbn: isbn,
          sprache: book.language || null,
          cover_url: book.imageLinks ? book.imageLinks.thumbnail : null
        };
      }
    }
  } catch (error) {
    console.error(`Fehler beim Abrufen der Manga-Daten für ${title} Band ${volume}:`, error.message);
  }
  return{};
}

async function importMangaDataFromExcel(filePath){
    const workbook = XLSX.readFile(filePath);
    const sheetName = workbook.SheetNames[0];
    const sheet = workbook.Sheets[sheetName];
    const data = XLSX.utils.sheet_to_json(sheet);

    const insertStmt = db.prepare(`
    INSERT INTO mangas (titel, band, genre, autor, verlag, isbn, sprache, cover_url, read, new_buy, double)
    VALUES (@titel, @band, @genre, @autor, @verlag, @isbn, @sprache, @cover_url, 'false', 'false', 'false')
    `);

    for (const row of data){
        const titel = row.Titel?.Trim();
        const band = Number(row.Band);
        const genre = row.Genre?.Trim() || null;

        if (!titel || isNaN(band)) {
            console.warn(`Überspringe Zeile: Ungültige Daten für Titel: ${titel}, Band: ${band}`);
            continue;
        }
        const mangaData = await fetchMangaData(titel, band);

        insertStmt.run({
            titel: titel,
            band: band,
            genre: genre,
            autor: mangaData.autor || null,
            verlag: mangaData.verlag || null,
            isbn: mangaData.isbn || null,
            sprache: mangaData.sprache || null,
            cover_url: mangaData.cover_url || null
        });
        console.log(`Importiere: ${titel} Band ${band}`);

    }

    
    console.log('Import abgeschlossen.');
}

if (require.main === module) {
    importMangaDataFromExcel('.data/manga.xlsx')
        .then(() => console.log('Import erfolgreich abgeschlossen.'))
        .catch(error => console.error('Fehler beim Importieren der Manga-Daten:', error));
}


    