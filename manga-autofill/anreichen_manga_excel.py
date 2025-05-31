import pandas as pd
import requests
import time
import os
import argparse
#=== Konfiguration ===#
parser = argparse.ArgumentParser(description="Anreichern von Manga-Daten in einer Excel-Datei")
parser.add_argument('--input', type=str, required=True, help='Pfad zur Eingabe-Excel-Datei')
input_args = parser.parse_args()

#=== Eingabe- und Ausgabedateien ===#
INPUNT_FILE = input_args.input
if not os.path.exists(INPUNT_FILE):
    raise FileNotFoundError(f"Eingabedatei nicht gefunden: {INPUNT_FILE}")
OUTPUT_FILE = os.path.splitext(INPUNT_FILE)[0] + "_anreichert.xlsx"
#=== Funktion zum Abrufen von Manga-Daten ===#
def fetch_manga_data(title, band, author=None):
    query = f"{title}- band: {band} manga"
    if author:
        query += f" by {author}"

    params = {
        'q': query,
        'limit': 1,
        'printType': 'books',
    }

    response = requests.get('https://www.googleapis.com/books/v1/volumes', params=params)
    if response.status_code !=200:
        return None
    
    items = response.json().get('items', [])
    if not items:
        return None
    
    volume = items[0].get('volumeInfo', {})
    industry_ids = volume.get('industryIdentifiers', [])
    isbn = next((id['identifier'] for id in industry_ids if id['type'] == 'ISBN_13'), None)
    if not isbn:
        isbn = next((id['identifier'] for id in industry_ids if id['type'] == 'ISBN_10'), None)
    if not isbn:
        return None
    return {
        "author": ", ".join(volume.get("authors", [])),
        "verlag": volume.get("publisher", ""),
        "isbn": isbn,
        "cover_url": volume.get("imageLinks", {}).get("thumbnail", ""),
    }

#=== Excel-Datei laden ===#
df = pd.read_excel(INPUNT_FILE)

#=== Manga-Daten anreichern ===#
for i , row in df.iterrows():
    title = row['title']
    author = row.get('author', None)
    band = row['band']
    if pd.isna(title) or pd.isna(band):
        print(f"Überspringe Zeile {i} wegen fehlender Titel oder Band.")
        continue
    if pd.isna(author):
        author = "Unbekannt"
    print(f"Verarbeite Manga:{title}, Band {band} von {author}")
    
    manga_data = fetch_manga_data(title, author)
    
    if manga_data:
        df.at[i, 'Autor'] = manga_data['author']
        df.at[i, 'Verlag'] = manga_data['verlag']
        df.at[i, 'ISBN'] = manga_data['isbn']
        df.at[i, 'Cover URL'] = manga_data['cover_url']
    else:
        print(f"Keine Daten gefunden für: {title}")
    
    time.sleep(1)  # Rate Limiting

#=== Anreicherte Daten speichern ===#
df.to_excel(OUTPUT_FILE, index=False)
print(f"Anreicherung abgeschlossen. Daten gespeichert in: {OUTPUT_FILE}")
#=== Ende des Skripts ===#