"use client"

import { Suspense, useEffect, useState } from "react"
import { useSearchParams, useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Skeleton } from "@/components/ui/skeleton"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Label } from "@/components/ui/label"
import { Checkbox } from "@/components/ui/checkbox"
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog"
import { ArrowLeft, Edit, Trash2, BookOpen, Star, Copy, ShoppingCart, Heart, Sparkles } from "lucide-react"
import { mangaAPI, type Manga } from "@/lib/api"
import { SimpleISBNScanner } from "@/components/simple-isbn-scanner"

function MangaDetailContent() {
  const searchParams = useSearchParams()
  const router = useRouter()
  const mangaId = searchParams.get("id")

  const [manga, setManga] = useState<Manga | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [isScannerOpen, setIsScannerOpen] = useState(false)
  const [isLoadingISBN, setIsLoadingISBN] = useState(false)
  const [status, setStatus] = useState<{ type: "success" | "error" | null; message: string }>({
    type: null,
    message: "",
  })

  useEffect(() => {
    if (!mangaId) {
      setError("Keine Manga-ID angegeben")
      setLoading(false)
      return
    }

    fetchManga()
  }, [mangaId])

  const fetchManga = async () => {
    if (!mangaId) return

    setLoading(true)
    setError(null)

    try {
      const response = await mangaAPI.getManga(mangaId)
      setManga(response.data)
    } catch (err) {
      setError("Manga nicht gefunden")
      console.error("Error fetching manga:", err)
    } finally {
      setLoading(false)
    }
  }

  const handleDeleteManga = async () => {
    if (!manga) return

    try {
      await mangaAPI.deleteManga(manga.id)
      setStatus({
        type: "success",
        message: "Manga erfolgreich gelöscht! 🗑️",
      })
      // Redirect to main page after deletion
      setTimeout(() => {
        router.push("/")
      }, 1500)
    } catch (error) {
      setStatus({
        type: "error",
        message: "Fehler beim Löschen des Manga! 😅",
      })
    }
  }

  const toggleStatus = async (field: "read" | "double" | "newbuy") => {
    if (!manga) return

    try {
      const updatedValue = !manga[field]
      await mangaAPI.updateManga(manga.id, { [field]: updatedValue })
      setManga({ ...manga, [field]: updatedValue })
      setStatus({
        type: "success",
        message: "Status erfolgreich aktualisiert! ✨",
      })
    } catch (error) {
      setStatus({
        type: "error",
        message: "Fehler beim Aktualisieren des Status! 😅",
      })
    }
  }

  const handleISBNScan = async (isbn: string) => {
    setIsScannerOpen(false)
    setIsLoadingISBN(true)

    try {
      const response = await mangaAPI.getISBNMetadata(isbn)

      if (response.data && manga) {
        setManga({
          ...manga,
          ...response.data,
          isbn: isbn,
        })

        setStatus({
          type: "success",
          message: `ISBN ${isbn} erfolgreich gescannt und Metadaten geladen! 📚`,
        })
      }
    } catch (error) {
      console.error("Error fetching ISBN metadata:", error)
      setStatus({
        type: "error",
        message: `ISBN ${isbn} gescannt, aber keine Metadaten gefunden. 😢`,
      })
    } finally {
      setIsLoadingISBN(false)
    }
  }

  const handleISBNLookup = async (isbn: string) => {
    if (!isbn || isbn.length < 10 || !manga) return

    setIsLoadingISBN(true)

    try {
      const response = await mangaAPI.getISBNMetadata(isbn)

      if (response.data) {
        setManga({
          ...manga,
          ...response.data,
          isbn: isbn,
        })

        setStatus({
          type: "success",
          message: `Metadaten für ISBN ${isbn} erfolgreich geladen! 📚`,
        })
      }
    } catch (error) {
      console.error("Error fetching ISBN metadata:", error)
      setStatus({
        type: "error",
        message: `Keine Metadaten für ISBN ${isbn} gefunden. 😢`,
      })
    } finally {
      setIsLoadingISBN(false)
    }
  }

  // Clear status after 3 seconds
  useEffect(() => {
    if (status.type) {
      const timer = setTimeout(() => {
        setStatus({ type: null, message: "" })
      }, 3000)
      return () => clearTimeout(timer)
    }
  }, [status.type])

  if (loading) {
    return (
      <div className="min-h-screen bg-background">
        <div className="container mx-auto p-6 space-y-6">
          <Skeleton className="h-10 w-32" />
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <Skeleton className="h-96 w-full" />
            <div className="lg:col-span-2 space-y-4">
              <Skeleton className="h-12 w-full" />
              <Skeleton className="h-32 w-full" />
              <Skeleton className="h-24 w-full" />
            </div>
          </div>
        </div>
      </div>
    )
  }

  if (error || !manga) {
    return (
      <div className="min-h-screen bg-background">
        <div className="container mx-auto p-6 space-y-6">
          <Button
            variant="outline"
            className="mb-4"
            onClick={() => {
              const params = new URLSearchParams(window.location.search)
              params.delete("id")
              const newUrl = params.toString() ? `/?${params.toString()}` : "/"
              router.push(newUrl)
            }}
          >
            <ArrowLeft className="h-4 w-4 mr-2" />
            Zurück zur Sammlung
          </Button>
          <Alert className="border-destructive bg-destructive/10">
            <AlertDescription className="font-medium text-destructive">{error || "Manga nicht gefunden"}</AlertDescription>
          </Alert>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-background">
      <div className="container mx-auto p-4 md:p-6 space-y-4 md:space-y-6">
        {/* Header */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <Button
            variant="outline"
            className="border-border hover:bg-accent w-full sm:w-auto"
            onClick={() => {
              // Erstelle neue URLSearchParams basierend auf den aktuellen searchParams
              const params = new URLSearchParams(searchParams.toString())
              params.delete("id") // Entferne nur die ID

              // Gehe zur Hauptseite mit allen anderen Parametern zurück
              const newUrl = params.toString() ? `/?${params.toString()}` : "/"
              router.push(newUrl)
            }}
          >
            <ArrowLeft className="h-4 w-4 mr-2" />
            Zurück zur Sammlung
          </Button>
          <div className="flex items-center gap-2 mx-auto sm:mx-0">
            <Sparkles className="h-5 w-5 md:h-6 md:w-6 text-brand-coral" />
            <h1 className="text-xl md:text-2xl font-bold text-foreground">
              Manga Details
            </h1>
            <Heart className="h-5 w-5 md:h-6 md:w-6 text-brand-violet" />
          </div>
        </div>

        {/* Status Alert */}
        {status.type && (
          <Alert
            className={`${status.type === "success" ? "border-brand-cyan bg-brand-cyan/10" : "border-destructive bg-destructive/10"} shadow-lg`}
          >
            <AlertDescription className="font-medium text-sm md:text-base">{status.message}</AlertDescription>
          </Alert>
        )}

        {/* Main Content */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 md:gap-6">
          {/* Cover Image */}
          <Card className="shadow-xl border-border order-1 lg:order-1">
            <CardContent className="p-4 md:p-6">
              <div className="aspect-[3/4] max-w-sm mx-auto lg:max-w-none bg-secondary rounded-lg flex items-center justify-center overflow-hidden shadow-lg">
                {manga.coverImage && manga.coverImage !== "/placeholder.svg?height=120&width=80" ? (
                  <img
                    src={manga.coverImage || "/placeholder.svg"}
                    alt={`Cover von ${manga.titel}`}
                    className="w-full h-full object-cover rounded-lg"
                    onError={(e) => {
                      const target = e.target as HTMLImageElement
                      target.style.display = "none"
                      target.nextElementSibling?.classList.remove("hidden")
                    }}
                  />
                ) : null}
                <div className="text-center text-muted-foreground">
                  <BookOpen className="h-12 w-12 md:h-16 md:w-16 mx-auto mb-2" />
                  <p className="text-xs md:text-sm">Kein Cover verfügbar</p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Details */}
          <div className="lg:col-span-2 space-y-4 md:space-y-6 order-2 lg:order-2">
            {/* Title and Actions */}
            <Card className="shadow-xl border-border">
              <CardHeader className="border-b p-4 md:p-6">
                <div className="flex flex-col space-y-4 md:space-y-0 md:flex-row md:items-center md:justify-between">
                  <CardTitle className="text-xl md:text-2xl text-foreground break-words">{manga.titel}</CardTitle>
                  <div className="flex flex-col sm:flex-row gap-2 w-full md:w-auto">
                    <Button
                      onClick={() => router.push(`/manga/edit/${mangaId}`)}
                      className="bg-primary text-primary-foreground hover:bg-primary/90 w-full sm:w-auto"
                      size="sm"
                    >
                      <Edit className="h-4 w-4 mr-2" />
                      Bearbeiten
                    </Button>
                    <AlertDialog>
                      <AlertDialogTrigger asChild>
                        <Button
                          variant="destructive"
                          className="bg-destructive text-destructive-foreground hover:bg-destructive/90 w-full sm:w-auto"
                          size="sm"
                        >
                          <Trash2 className="h-4 w-4 mr-2" />
                          Löschen
                        </Button>
                      </AlertDialogTrigger>
                      <AlertDialogContent className="mx-4 max-w-md">
                        <AlertDialogHeader>
                          <AlertDialogTitle>Manga löschen</AlertDialogTitle>
                          <AlertDialogDescription className="text-sm">
                            Möchtest du "{manga.titel}" wirklich löschen? Diese Aktion kann nicht rückgängig gemacht
                            werden.
                          </AlertDialogDescription>
                        </AlertDialogHeader>
                        <AlertDialogFooter className="flex-col sm:flex-row gap-2">
                          <AlertDialogCancel className="w-full sm:w-auto">Abbrechen</AlertDialogCancel>
                          <AlertDialogAction
                            onClick={handleDeleteManga}
                            className="bg-destructive text-destructive-foreground hover:bg-destructive/90 w-full sm:w-auto"
                          >
                            Löschen
                          </AlertDialogAction>
                        </AlertDialogFooter>
                      </AlertDialogContent>
                    </AlertDialog>
                  </div>
                </div>
              </CardHeader>
              <CardContent className="p-4 md:p-6 space-y-4">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <Label className="text-sm font-medium text-muted-foreground">Band</Label>
                    <div className="mt-1">
                      <Badge variant="outline" className="border-border text-foreground">
                        Band {manga.band}
                      </Badge>
                    </div>
                  </div>
                  <div>
                    <Label className="text-sm font-medium text-muted-foreground">Sprache</Label>
                    <div className="mt-1">
                      <Badge variant="outline" className="border-border text-muted-foreground">
                        {manga.sprache}
                      </Badge>
                    </div>
                  </div>
                  <div>
                    <Label className="text-sm font-medium text-muted-foreground">Autor</Label>
                    <p className="text-sm mt-1 break-words">
                      {manga.autor || <span className="text-muted-foreground italic">Nicht angegeben</span>}
                    </p>
                  </div>
                  <div>
                    <Label className="text-sm font-medium text-muted-foreground">Verlag</Label>
                    <p className="text-sm mt-1 break-words">
                      {manga.verlag || <span className="text-muted-foreground italic">Nicht angegeben</span>}
                    </p>
                  </div>
                  <div className="sm:col-span-2">
                    <Label className="text-sm font-medium text-muted-foreground">ISBN</Label>
                    <p className="text-sm font-mono mt-1 break-all">{manga.isbn}</p>
                  </div>
                </div>

                <div>
                  <Label className="text-sm font-medium text-muted-foreground">Genre</Label>
                  <div className="flex flex-wrap gap-2 mt-2">
                    {manga.genre.split(",").map((g, i) => (
                      <Badge key={i} variant="secondary" className="bg-brand-violet/15 text-brand-violet border-0 text-xs">
                        {g.trim()}
                      </Badge>
                    ))}
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Status */}
            <Card className="shadow-xl border-border">
              <CardHeader className="border-b p-4 md:p-6">
                <CardTitle className="text-foreground text-lg md:text-xl">Status</CardTitle>
              </CardHeader>
              <CardContent className="p-4 md:p-6">
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 md:gap-4">
                  <div
                    className={`p-3 md:p-4 rounded-lg border-2 cursor-pointer transition-all ${
                      manga.read
                        ? "border-brand-cyan bg-brand-cyan/10 shadow-md"
                        : "border-border bg-secondary/40 hover:border-brand-cyan/50"
                    }`}
                    onClick={() => toggleStatus("read")}
                  >
                    <div className="flex items-center space-x-2 md:space-x-3">
                      <Checkbox checked={manga.read} readOnly />
                      <div className="min-w-0 flex-1">
                        <div className="flex items-center gap-2">
                          <Star className="h-4 w-4 text-brand-cyan flex-shrink-0" />
                          <span className="font-medium text-sm md:text-base">Gelesen</span>
                        </div>
                        <p className="text-xs text-muted-foreground">Klicken zum Ändern</p>
                      </div>
                    </div>
                  </div>

                  <div
                    className={`p-3 md:p-4 rounded-lg border-2 cursor-pointer transition-all ${
                      manga.double
                        ? "border-brand-coral bg-brand-coral/10 shadow-md"
                        : "border-border bg-secondary/40 hover:border-brand-coral/50"
                    }`}
                    onClick={() => toggleStatus("double")}
                  >
                    <div className="flex items-center space-x-2 md:space-x-3">
                      <Checkbox checked={manga.double} readOnly />
                      <div className="min-w-0 flex-1">
                        <div className="flex items-center gap-2">
                          <Copy className="h-4 w-4 text-brand-coral flex-shrink-0" />
                          <span className="font-medium text-sm md:text-base">Doppelt</span>
                        </div>
                        <p className="text-xs text-muted-foreground">Klicken zum Ändern</p>
                      </div>
                    </div>
                  </div>

                  <div
                    className={`p-3 md:p-4 rounded-lg border-2 cursor-pointer transition-all sm:col-span-2 lg:col-span-1 ${
                      manga.newbuy
                        ? "border-brand-violet bg-brand-violet/10 shadow-md"
                        : "border-border bg-secondary/40 hover:border-brand-violet/50"
                    }`}
                    onClick={() => toggleStatus("newbuy")}
                  >
                    <div className="flex items-center space-x-2 md:space-x-3">
                      <Checkbox checked={manga.newbuy} readOnly />
                      <div className="min-w-0 flex-1">
                        <div className="flex items-center gap-2">
                          <ShoppingCart className="h-4 w-4 text-brand-violet flex-shrink-0" />
                          <span className="font-medium text-sm md:text-base">Neu kaufen</span>
                        </div>
                        <p className="text-xs text-muted-foreground">Klicken zum Ändern</p>
                      </div>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>

        {/* ISBN Scanner Dialog */}
        <Dialog open={isScannerOpen} onOpenChange={setIsScannerOpen}>
          <DialogContent className="mx-4 max-w-md max-h-[90vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle className="text-foreground text-lg">ISBN scannen 📷</DialogTitle>
            </DialogHeader>
            <SimpleISBNScanner onScan={handleISBNScan} onClose={() => setIsScannerOpen(false)} />
          </DialogContent>
        </Dialog>
      </div>
    </div>
  )
}

export default function MangaDetailPage() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen bg-background">
          <div className="container mx-auto p-6 space-y-6">
            <Skeleton className="h-10 w-32" />
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              <Skeleton className="h-96 w-full" />
              <div className="lg:col-span-2 space-y-4">
                <Skeleton className="h-12 w-full" />
                <Skeleton className="h-32 w-full" />
                <Skeleton className="h-24 w-full" />
              </div>
            </div>
          </div>
        </div>
      }
    >
      <MangaDetailContent />
    </Suspense>
  )
}
