"use client"

import { useEffect, useState } from "react"
import { useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Checkbox } from "@/components/ui/checkbox"
import { Skeleton } from "@/components/ui/skeleton"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { ArrowLeft, Loader2, Search, Camera, Heart, Sparkles } from "lucide-react"
import { mangaAPI, type Manga } from "@/lib/api"
import { SimpleISBNScanner } from "@/components/simple-isbn-scanner"

export default function EditMangaPage({ params }: { params: { id: string } }) {
  const router = useRouter()
  const mangaId = params.id

  const [manga, setManga] = useState<Manga | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
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

  const handleUpdateManga = async () => {
    if (!manga || !manga.titel) {
      setStatus({
        type: "error",
        message: "Titel ist erforderlich! 📝",
      })
      return
    }

    try {
      setSaving(true)
      const { id, createdAt, updatedAt, ...updateData } = manga
      await mangaAPI.updateManga(id, updateData)

      setStatus({
        type: "success",
        message: "Manga erfolgreich aktualisiert! 🎉",
      })

      // Redirect back to detail page after successful update
      setTimeout(() => {
        router.push(`/manga?id=${mangaId}`)
      }, 1000)
    } catch (error) {
      setStatus({
        type: "error",
        message: "Fehler beim Aktualisieren des Manga! 😅",
      })
    } finally {
      setSaving(false)
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
          <div className="grid grid-cols-1 gap-6">
            <Skeleton className="h-96 w-full" />
          </div>
        </div>
      </div>
    )
  }

  if (error || !manga) {
    return (
      <div className="min-h-screen bg-background">
        <div className="container mx-auto p-6 space-y-6">
          <Button variant="outline" className="mb-4" onClick={() => router.back()}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Zurück
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
            onClick={() => router.push(`/manga?id=${mangaId}`)}
          >
            <ArrowLeft className="h-4 w-4 mr-2" />
            Zurück zur Detailansicht
          </Button>
          <div className="flex items-center gap-2 mx-auto sm:mx-0">
            <Sparkles className="h-5 w-5 md:h-6 md:w-6 text-brand-coral" />
            <h1 className="text-xl md:text-2xl font-bold text-foreground">
              Manga Bearbeiten
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

        {/* Edit Form */}
        <Card className="shadow-xl border-border">
          <CardHeader className="border-b p-4 md:p-6">
            <CardTitle className="text-foreground text-lg md:text-xl">Manga bearbeiten ✏️</CardTitle>
          </CardHeader>
          <CardContent className="p-4 md:p-6">
            <div className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* Left Column */}
                <div className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="titel">Titel *</Label>
                    <Input
                      id="titel"
                      value={manga.titel}
                      onChange={(e) => setManga({ ...manga, titel: e.target.value })}
                      placeholder="Manga-Titel"
                      className="focus:border-primary"
                      disabled={saving}
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label htmlFor="band">Band</Label>
                      <Input
                        id="band"
                        value={manga.band}
                        onChange={(e) => setManga({ ...manga, band: e.target.value })}
                        placeholder="Band-Nr."
                        className="focus:border-primary"
                        disabled={saving}
                      />
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="sprache">Sprache</Label>
                      <Input
                        id="sprache"
                        value={manga.sprache}
                        onChange={(e) => setManga({ ...manga, sprache: e.target.value })}
                        placeholder="Deutsch"
                        className="focus:border-primary"
                        disabled={saving}
                      />
                    </div>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="genre">Genre</Label>
                    <Input
                      id="genre"
                      value={manga.genre}
                      onChange={(e) => setManga({ ...manga, genre: e.target.value })}
                      placeholder="z.B. Shonen, Action"
                      className="focus:border-primary"
                      disabled={saving}
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="autor">Autor</Label>
                    <Input
                      id="autor"
                      value={manga.autor}
                      onChange={(e) => setManga({ ...manga, autor: e.target.value })}
                      placeholder="Autor-Name"
                      className="focus:border-primary"
                      disabled={saving}
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="verlag">Verlag</Label>
                    <Input
                      id="verlag"
                      value={manga.verlag}
                      onChange={(e) => setManga({ ...manga, verlag: e.target.value })}
                      placeholder="Verlag"
                      className="focus:border-primary"
                      disabled={saving}
                    />
                  </div>
                </div>

                {/* Right Column */}
                <div className="space-y-4">
                  <div className="space-y-2">
                    <div className="flex gap-2">
                      <div className="flex-1">
                        <Label htmlFor="isbn">ISBN</Label>
                        <Input
                          id="isbn"
                          value={manga.isbn}
                          onChange={(e) => setManga({ ...manga, isbn: e.target.value })}
                          placeholder="ISBN-Nummer"
                          className="focus:border-primary"
                          disabled={saving || isLoadingISBN}
                        />
                      </div>
                      <div className="flex flex-col justify-end">
                        <Button
                          type="button"
                          variant="outline"
                          size="icon"
                          onClick={() => handleISBNLookup(manga.isbn)}
                          disabled={saving || isLoadingISBN || !manga.isbn}
                          className="h-10 w-10"
                        >
                          {isLoadingISBN ? (
                            <Loader2 className="h-4 w-4 animate-spin" />
                          ) : (
                            <Search className="h-4 w-4" />
                          )}
                        </Button>
                      </div>
                      <div className="flex flex-col justify-end">
                        <Button
                          type="button"
                          variant="outline"
                          size="icon"
                          onClick={() => setIsScannerOpen(true)}
                          disabled={saving || isLoadingISBN}
                          className="h-10 w-10"
                        >
                          <Camera className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="coverImage">Cover-Bild URL</Label>
                    <Input
                      id="coverImage"
                      value={manga.coverImage}
                      onChange={(e) => setManga({ ...manga, coverImage: e.target.value })}
                      placeholder="URL zum Cover-Bild"
                      className="focus:border-primary"
                      disabled={saving}
                    />
                    {manga.coverImage && manga.coverImage !== "/placeholder.svg?height=120&width=80" && (
                      <div className="mt-2 flex justify-center">
                        <img
                          src={manga.coverImage || "/placeholder.svg"}
                          alt="Cover Vorschau"
                          className="h-40 object-contain rounded-md border border-border"
                          onError={(e) => {
                            const target = e.target as HTMLImageElement
                            target.src = "/placeholder.svg?height=120&width=80"
                          }}
                        />
                      </div>
                    )}
                  </div>

                  <div className="space-y-3 mt-4">
                    <div className="flex items-center space-x-2">
                      <Checkbox
                        id="read"
                        checked={manga.read}
                        onCheckedChange={(checked) => setManga({ ...manga, read: checked as boolean })}
                        disabled={saving}
                      />
                      <Label htmlFor="read">Gelesen ⭐</Label>
                    </div>

                    <div className="flex items-center space-x-2">
                      <Checkbox
                        id="double"
                        checked={manga.double}
                        onCheckedChange={(checked) => setManga({ ...manga, double: checked as boolean })}
                        disabled={saving}
                      />
                      <Label htmlFor="double">Doppelt vorhanden 📚</Label>
                    </div>

                    <div className="flex items-center space-x-2">
                      <Checkbox
                        id="newbuy"
                        checked={manga.newbuy}
                        onCheckedChange={(checked) => setManga({ ...manga, newbuy: checked as boolean })}
                        disabled={saving}
                      />
                      <Label htmlFor="newbuy">Neu kaufen 🛒</Label>
                    </div>
                  </div>
                </div>
              </div>

              <div className="flex flex-col sm:flex-row gap-4 pt-4">
                <Button
                  onClick={handleUpdateManga}
                  className="flex-1 bg-brand-coral text-background hover:bg-brand-coral/90"
                  disabled={saving}
                >
                  {saving ? <Loader2 className="h-4 w-4 animate-spin mr-2" /> : null}
                  Änderungen speichern ✨
                </Button>
                <Button
                  variant="outline"
                  onClick={() => router.push(`/manga?id=${mangaId}`)}
                  className="flex-1"
                  disabled={saving}
                >
                  Abbrechen
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>

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
