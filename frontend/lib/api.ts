// API Client for Manga Inventory REST API

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "https://manga-api.phudevelopement.xyz"
const API_KEY = process.env.NEXT_PUBLIC_API_KEY || ""

export interface Manga {
  id: string
  titel: string
  band: string
  genre: string
  autor: string
  verlag: string
  isbn: string
  sprache: string
  coverImage: string
  read: boolean
  double: boolean
  newbuy: boolean
  createdAt?: string
  updatedAt?: string
}

export interface CreateMangaRequest extends Omit<Manga, "id" | "createdAt" | "updatedAt"> {}
export interface UpdateMangaRequest extends Partial<CreateMangaRequest> {}

export interface ApiResponse<T> {
  data: T
  message?: string
  error?: string
}

export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  limit: number
  totalPages: number
}

// Helper function to transform API response to Manga interface
function transformMangaFromAPI(row: any): Manga {
  return {
    id: row.id,
    titel: row.titel || "",
    band: row.band || "",
    genre: row.genre || "",
    autor: row.autor || "",
    verlag: row.verlag || "",
    isbn: row.isbn || "",
    sprache: row.sprache || "Deutsch",
    coverImage: row.cover_image || "/placeholder.svg?height=120&width=80",
    read: row.read || false,
    double: row.double || false,
    newbuy: row.newbuy || false,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  }
}

// Helper function to transform Manga interface to API request
function transformMangaToAPI(manga: CreateMangaRequest | UpdateMangaRequest) {
  const result: any = {}

  if (manga.titel !== undefined) result.titel = manga.titel
  if (manga.band !== undefined) result.band = manga.band
  if (manga.genre !== undefined) result.genre = manga.genre
  if (manga.autor !== undefined) result.autor = manga.autor
  if (manga.verlag !== undefined) result.verlag = manga.verlag
  if (manga.isbn !== undefined) result.isbn = manga.isbn
  if (manga.sprache !== undefined) result.sprache = manga.sprache
  if (manga.coverImage !== undefined) result.cover_image = manga.coverImage
  if (manga.read !== undefined) result.read = manga.read
  if (manga.double !== undefined) result.double = manga.double
  if (manga.newbuy !== undefined) result.newbuy = manga.newbuy

  return result
}

// Generic fetch wrapper with authentication
async function apiFetch<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const headers: HeadersInit = {
    "Content-Type": "application/json",
    "X-API-Key": API_KEY,
    ...options.headers,
  }

  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    ...options,
    headers,
  })

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}))
    throw new Error(errorData.message || errorData.error || `API Error: ${response.status}`)
  }

  return response.json()
}

// API Client Class
class MangaAPI {
  // GET all manga with optional filters and sorting
  async getMangas(params?: {
    page?: number
    limit?: number
    search?: string
    genre?: string
    autor?: string
    verlag?: string
    sprache?: string
    status?: string
    band?: string
    sortBy?: string
    sortDirection?: "asc" | "desc"
  }): Promise<ApiResponse<PaginatedResponse<Manga>>> {
    try {
      const searchParams = new URLSearchParams()

      if (params?.page) searchParams.set("page", params.page.toString())
      if (params?.limit) searchParams.set("limit", params.limit.toString())
      if (params?.search) searchParams.set("search", params.search)
      if (params?.genre) searchParams.set("genre", params.genre)
      if (params?.autor) searchParams.set("autor", params.autor)
      if (params?.verlag) searchParams.set("verlag", params.verlag)
      if (params?.sprache) searchParams.set("sprache", params.sprache)
      if (params?.sortBy) searchParams.set("sortBy", params.sortBy)
      if (params?.sortDirection) searchParams.set("sortOrder", params.sortDirection)

      // Map status to API parameters
      if (params?.status) {
        switch (params.status) {
          case "read":
            searchParams.set("read", "true")
            break
          case "unread":
            searchParams.set("read", "false")
            break
          case "double":
            searchParams.set("double", "true")
            break
          case "newbuy":
            searchParams.set("newbuy", "true")
            break
        }
      }

      const queryString = searchParams.toString()
      const endpoint = `/api/manga${queryString ? `?${queryString}` : ""}`

      const response = await apiFetch<{
        data: any[]
        pagination: {
          page: number
          limit: number
          total: number
          pages: number
        }
      }>(endpoint)

      const transformedData = response.data.map(transformMangaFromAPI)

      return {
        data: {
          data: transformedData,
          total: response.pagination.total,
          page: response.pagination.page,
          limit: response.pagination.limit,
          totalPages: response.pagination.pages,
        },
        message: "Manga retrieved successfully",
      }
    } catch (error) {
      console.error("Error fetching manga:", error)
      throw error
    }
  }

  // GET single manga by ID
  async getManga(id: string): Promise<ApiResponse<Manga>> {
    try {
      const data = await apiFetch<any>(`/api/manga/${id}`)

      return {
        data: transformMangaFromAPI(data),
        message: "Manga retrieved successfully",
      }
    } catch (error) {
      console.error("Error fetching manga:", error)
      throw error
    }
  }

  // POST create new manga
  async createManga(manga: CreateMangaRequest): Promise<ApiResponse<Manga>> {
    try {
      const apiManga = transformMangaToAPI(manga)

      const data = await apiFetch<any>("/api/manga", {
        method: "POST",
        body: JSON.stringify(apiManga),
      })

      return {
        data: transformMangaFromAPI(data),
        message: "Manga created successfully",
      }
    } catch (error) {
      console.error("Error creating manga:", error)
      throw error
    }
  }

  // PUT update manga
  async updateManga(id: string, manga: UpdateMangaRequest): Promise<ApiResponse<Manga>> {
    try {
      const apiManga = transformMangaToAPI(manga)

      const data = await apiFetch<any>(`/api/manga/${id}`, {
        method: "PUT",
        body: JSON.stringify(apiManga),
      })

      return {
        data: transformMangaFromAPI(data),
        message: "Manga updated successfully",
      }
    } catch (error) {
      console.error("Error updating manga:", error)
      throw error
    }
  }

  // DELETE manga
  async deleteManga(id: string): Promise<ApiResponse<void>> {
    try {
      await apiFetch<any>(`/api/manga/${id}`, {
        method: "DELETE",
      })

      return {
        data: undefined,
        message: "Manga deleted successfully",
      }
    } catch (error) {
      console.error("Error deleting manga:", error)
      throw error
    }
  }

  // DELETE multiple manga
  async deleteMangas(ids: string[]): Promise<ApiResponse<void>> {
    try {
      // API doesn't support bulk delete, so we delete one by one
      await Promise.all(ids.map((id) => this.deleteManga(id)))

      return {
        data: undefined,
        message: `${ids.length} manga deleted successfully`,
      }
    } catch (error) {
      console.error("Error deleting manga:", error)
      throw error
    }
  }

  // POST import manga from Excel
  async importMangas(file: File): Promise<ApiResponse<{ imported: number; errors: string[] }>> {
    try {
      // Import XLSX dynamically to avoid SSR issues
      const XLSX = await import("xlsx")

      const buffer = await file.arrayBuffer()
      const workbook = XLSX.read(buffer, { type: "array" })
      const sheetName = workbook.SheetNames[0]
      const worksheet = workbook.Sheets[sheetName]
      const jsonData = XLSX.utils.sheet_to_json(worksheet)

      const errors: string[] = []
      let importedCount = 0

      for (let i = 0; i < jsonData.length; i++) {
        const row: any = jsonData[i]
        try {
          const manga: CreateMangaRequest = {
            titel: row.title || row.Title || row.titel || row.Titel || "",
            band: row.band || row.Band || "",
            genre: row.genre || row.Genre || "",
            autor: row.autor || row.Autor || "",
            verlag: row.verlag || row.Verlag || "",
            isbn: row.isbn || row.ISBN || "",
            sprache: row.sprache || row.Sprache || "Deutsch",
            coverImage: "/placeholder.svg?height=120&width=80",
            read: Boolean(row.read || row.Read),
            double: Boolean(row.double || row.Double),
            newbuy: Boolean(row.new_buy || row.New_Buy || row.newbuy),
          }

          if (!manga.titel) {
            errors.push(`Row ${i + 2}: Title is required`)
            continue
          }

          await this.createManga(manga)
          importedCount++
        } catch (error) {
          errors.push(`Row ${i + 2}: ${error}`)
        }
      }

      return {
        data: {
          imported: importedCount,
          errors,
        },
        message: `Successfully imported ${importedCount} manga`,
      }
    } catch (error) {
      console.error("Error importing manga:", error)
      throw error
    }
  }

  // GET statistics
  async getStats(): Promise<
    ApiResponse<{
      total: number
      read: number
      doubles: number
      newbuys: number
      byGenre: Record<string, number>
      byAutor: Record<string, number>
      byVerlag: Record<string, number>
    }>
  > {
    try {
      // Get summary stats from API
      const summaryData = await apiFetch<{
        total: string
        read: string
        duplicates: string
        to_buy: string
      }>("/api/manga/stats/summary")

      // For detailed stats (byGenre, byAutor, byVerlag), we need to fetch all manga
      // This could be optimized with additional API endpoints in the future
      const allMangaResponse = await this.getMangas({ limit: 1000 })
      const mangas = allMangaResponse.data.data

      const stats = {
        total: parseInt(summaryData.total) || 0,
        read: parseInt(summaryData.read) || 0,
        doubles: parseInt(summaryData.duplicates) || 0,
        newbuys: parseInt(summaryData.to_buy) || 0,
        byGenre: {} as Record<string, number>,
        byAutor: {} as Record<string, number>,
        byVerlag: {} as Record<string, number>,
      }

      // Count by genre
      mangas.forEach((manga) => {
        if (manga.genre) {
          const genres = manga.genre.split(",").map((g: string) => g.trim())
          genres.forEach((genre) => {
            if (genre) {
              stats.byGenre[genre] = (stats.byGenre[genre] || 0) + 1
            }
          })
        }
      })

      // Count by author
      mangas.forEach((manga) => {
        if (manga.autor) {
          stats.byAutor[manga.autor] = (stats.byAutor[manga.autor] || 0) + 1
        }
      })

      // Count by publisher
      mangas.forEach((manga) => {
        if (manga.verlag) {
          stats.byVerlag[manga.verlag] = (stats.byVerlag[manga.verlag] || 0) + 1
        }
      })

      return {
        data: stats,
        message: "Statistics retrieved successfully",
      }
    } catch (error) {
      console.error("Error fetching stats:", error)
      throw error
    }
  }

  // GET metadata for ISBN (uses external APIs - Google Books / Open Library)
  async getISBNMetadata(isbn: string): Promise<ApiResponse<Partial<Manga>>> {
    try {
      // First try Google Books API
      const googleBooksResponse = await fetch(`https://www.googleapis.com/books/v1/volumes?q=isbn:${isbn}`)
      const googleData = await googleBooksResponse.json()

      if (googleData.totalItems > 0) {
        const book = googleData.items[0].volumeInfo

        const mangaData = {
          titel: book.title || "",
          autor: book.authors ? book.authors.join(", ") : "",
          verlag: book.publisher || "",
          isbn: isbn,
          genre: book.categories ? book.categories.join(", ") : "",
          sprache: book.language === "de" ? "Deutsch" : book.language || "Deutsch",
          coverImage: book.imageLinks?.thumbnail || "",
        }

        return {
          data: mangaData,
          message: "Metadata retrieved successfully",
        }
      }

      // If Google Books fails, try Open Library as fallback
      const openLibraryResponse = await fetch(
        `https://openlibrary.org/api/books?bibkeys=ISBN:${isbn}&format=json&jscmd=data`,
      )
      const openLibraryData = await openLibraryResponse.json()

      if (openLibraryData[`ISBN:${isbn}`]) {
        const book = openLibraryData[`ISBN:${isbn}`]

        const mangaData = {
          titel: book.title || "",
          autor: book.authors ? book.authors.map((a: any) => a.name).join(", ") : "",
          verlag: book.publishers ? book.publishers[0].name : "",
          isbn: isbn,
          genre: "",
          sprache: "Deutsch",
          coverImage: book.cover?.medium || "",
        }

        return {
          data: mangaData,
          message: "Metadata retrieved successfully",
        }
      }

      // No data found
      throw new Error("No metadata found for this ISBN")
    } catch (error) {
      console.error("Error fetching ISBN metadata:", error)
      throw error
    }
  }
}

export const mangaAPI = new MangaAPI()
