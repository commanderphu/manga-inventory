#!/usr/bin/env node

/**
 * Batch service to find and update missing cover images for manga in the database
 *
 * Usage:
 *   node find-missing-covers.js [options]
 *
 * Options:
 *   --dry-run    Only show what would be updated, don't actually update
 *   --limit N    Only process N manga (default: all)
 */

const { Pool } = require('pg');
const https = require('https');
const http = require('http');

// Parse command line arguments
const args = process.argv.slice(2);
const isDryRun = args.includes('--dry-run');
const limitIndex = args.indexOf('--limit');
const limit = limitIndex !== -1 ? parseInt(args[limitIndex + 1]) : null;

// Database connection
const pool = new Pool({
  host: process.env.DB_HOST || 'central_postgres',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'manga_inventory',
  user: process.env.DB_USER || 'manga_admin',
  password: process.env.DB_PASSWORD,
});

// Helper to make HTTP GET requests
function httpGet(url) {
  return new Promise((resolve, reject) => {
    const client = url.startsWith('https') ? https : http;
    client.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          resolve(data);
        } else {
          reject(new Error(`HTTP ${res.statusCode}`));
        }
      });
    }).on('error', reject);
  });
}

// Helper to check if URL exists
function urlExists(url) {
  return new Promise((resolve) => {
    const client = url.startsWith('https') ? https : http;
    const request = client.request(url, { method: 'HEAD' }, (res) => {
      resolve(res.statusCode === 200);
    });
    request.on('error', () => resolve(false));
    request.end();
  });
}

// Lookup cover from Google Books API
async function lookupGoogleBooks(isbn) {
  try {
    const cleanIsbn = isbn.replace(/[^0-9X]/g, '');
    const url = `https://www.googleapis.com/books/v1/volumes?q=isbn:${cleanIsbn}`;
    const data = JSON.parse(await httpGet(url));

    if (data.totalItems > 0) {
      const volumeInfo = data.items[0].volumeInfo;
      const imageLinks = volumeInfo.imageLinks;

      if (imageLinks) {
        // Try to get the best quality image
        const coverUrl = imageLinks.extraLarge || imageLinks.large ||
                        imageLinks.medium || imageLinks.small ||
                        imageLinks.thumbnail || imageLinks.smallThumbnail;

        if (coverUrl) {
          // Convert http to https
          return coverUrl.replace('http://', 'https://');
        }
      }
    }
  } catch (e) {
    // Ignore errors, try next method
  }
  return null;
}

// Lookup cover from Open Library
async function lookupOpenLibrary(isbn) {
  try {
    const cleanIsbn = isbn.replace(/[^0-9X]/g, '');
    const coverUrl = `https://covers.openlibrary.org/b/isbn/${cleanIsbn}-L.jpg`;

    // Check if cover exists
    const exists = await urlExists(coverUrl);
    if (exists) {
      return coverUrl;
    }
  } catch (e) {
    // Ignore errors
  }
  return null;
}

// Find cover image for a manga
async function findCoverImage(manga) {
  console.log(`  Searching for cover: ${manga.titel}${manga.band ? ` Band ${manga.band}` : ''}`);

  // If ISBN exists, try ISBN-based lookup
  if (manga.isbn) {
    console.log(`    Trying ISBN ${manga.isbn}...`);

    // Try Google Books
    const googleCover = await lookupGoogleBooks(manga.isbn);
    if (googleCover) {
      console.log(`    ✓ Found on Google Books: ${googleCover}`);
      return googleCover;
    }

    // Try Open Library
    const openLibraryCover = await lookupOpenLibrary(manga.isbn);
    if (openLibraryCover) {
      console.log(`    ✓ Found on Open Library: ${openLibraryCover}`);
      return openLibraryCover;
    }
  }

  console.log(`    ✗ No cover found`);
  return null;
}

// Main function
async function main() {
  console.log('🔍 Manga Cover Finder');
  console.log('='.repeat(50));
  console.log(`Mode: ${isDryRun ? 'DRY RUN (no changes will be made)' : 'LIVE (will update database)'}`);
  if (limit) {
    console.log(`Limit: ${limit} manga`);
  }
  console.log('='.repeat(50));
  console.log();

  try {
    // Find all manga without cover images
    let query = `
      SELECT id, titel, band, isbn, autor, verlag
      FROM manga
      WHERE cover_image IS NULL
      ORDER BY created_at DESC
    `;

    if (limit) {
      query += ` LIMIT ${limit}`;
    }

    const result = await pool.query(query);
    const mangaList = result.rows;

    console.log(`Found ${mangaList.length} manga without cover images\n`);

    if (mangaList.length === 0) {
      console.log('✓ All manga have cover images!');
      return;
    }

    let foundCount = 0;
    let updatedCount = 0;

    for (const manga of mangaList) {
      console.log(`\n[${mangaList.indexOf(manga) + 1}/${mangaList.length}] ${manga.titel}`);

      const coverUrl = await findCoverImage(manga);

      if (coverUrl) {
        foundCount++;

        if (!isDryRun) {
          // Update database
          await pool.query(
            'UPDATE manga SET cover_image = $1, updated_at = NOW() WHERE id = $2',
            [coverUrl, manga.id]
          );
          updatedCount++;
          console.log(`    ✓ Updated in database`);
        } else {
          console.log(`    → Would update: ${coverUrl}`);
        }
      }

      // Small delay to avoid rate limiting
      await new Promise(resolve => setTimeout(resolve, 500));
    }

    console.log('\n' + '='.repeat(50));
    console.log('Summary:');
    console.log(`  Total processed: ${mangaList.length}`);
    console.log(`  Covers found: ${foundCount}`);
    if (!isDryRun) {
      console.log(`  Database updated: ${updatedCount}`);
    }
    console.log('='.repeat(50));

  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

// Run the script
main().catch(console.error);
