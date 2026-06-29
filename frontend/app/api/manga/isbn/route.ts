import { type NextRequest, NextResponse } from "next/server"

async function fetchMangaDex(title: string): Promise<{ coverUrl: string; genres: string[] } | null> {
  try {
    const searchRes = await fetch(
      `https://api.mangadex.org/manga?title=${encodeURIComponent(title)}&limit=5&includes[]=cover_art&contentRating[]=safe&contentRating[]=suggestive&contentRating[]=erotica`,
      { headers: { "User-Agent": "manga-inventory/1.0" } }
    )
    if (!searchRes.ok) return null
    const searchData = await searchRes.json()
    if (!searchData.data?.length) return null

    const manga = searchData.data[0]
    const mangaId = manga.id

    // Tags → Genres
    const genres: string[] = manga.attributes?.tags
      ?.filter((t: any) => t.attributes?.group === "genre")
      .map((t: any) => t.attributes?.name?.en)
      .filter(Boolean) ?? []

    // Cover-URL aus relationships
    const coverRel = manga.relationships?.find((r: any) => r.type === "cover_art")
    let coverUrl = ""
    if (coverRel?.attributes?.fileName) {
      coverUrl = `https://uploads.mangadex.org/covers/${mangaId}/${coverRel.attributes.fileName}.512.jpg`
    }

    return { coverUrl, genres }
  } catch {
    return null
  }
}

// GET /api/manga/isbn?isbn=9783551791429
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const isbn = searchParams.get("isbn")

    if (!isbn) {
      return NextResponse.json({ error: "ISBN is required" }, { status: 400 })
    }

    let mangaData: Record<string, string> | null = null

    // 1. Google Books
    const googleRes = await fetch(`https://www.googleapis.com/books/v1/volumes?q=isbn:${isbn}`)
    const googleData = await googleRes.json()
    if (googleData.totalItems > 0) {
      const book = googleData.items[0].volumeInfo
      mangaData = {
        titel: book.title || "",
        autor: book.authors?.join(", ") || "",
        verlag: book.publisher || "",
        isbn,
        genre: book.categories?.join(", ") || "",
        sprache: book.language || "de",
        coverImage: book.imageLinks?.thumbnail?.replace("http://", "https://") || "",
        description: book.description || "",
      }
    }

    // 2. Open Library als Fallback
    if (!mangaData) {
      const olRes = await fetch(
        `https://openlibrary.org/api/books?bibkeys=ISBN:${isbn}&format=json&jscmd=data`
      )
      const olData = await olRes.json()
      const book = olData[`ISBN:${isbn}`]
      if (book) {
        mangaData = {
          titel: book.title || "",
          autor: book.authors?.map((a: any) => a.name).join(", ") || "",
          verlag: book.publishers?.[0]?.name || "",
          isbn,
          genre: "",
          sprache: "de",
          coverImage: book.cover?.large || book.cover?.medium || "",
          description: book.excerpts?.[0]?.text || "",
        }
      }
    }

    if (!mangaData) {
      return NextResponse.json({ error: "No metadata found for this ISBN" }, { status: 404 })
    }

    // 3. MangaDex für bessere Cover + Genres (anreichern)
    if (mangaData.titel) {
      const mdData = await fetchMangaDex(mangaData.titel)
      if (mdData) {
        if (mdData.coverUrl) mangaData.coverImage = mdData.coverUrl
        if (mdData.genres.length > 0) mangaData.genre = mdData.genres.join(", ")
      }
    }

    return NextResponse.json({ data: mangaData, message: "Metadata retrieved successfully" })
  } catch (error) {
    console.error("GET /api/manga/isbn error:", error)
    return NextResponse.json({ error: "Failed to retrieve metadata" }, { status: 500 })
  }
}
