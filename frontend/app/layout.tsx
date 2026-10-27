import type React from "react"
import type { Metadata } from "next"
import { Inter, Space_Grotesk } from "next/font/google"
import "./globals.css"

const inter = Inter({ subsets: ["latin"], variable: "--font-inter" })
const spaceGrotesk = Space_Grotesk({ subsets: ["latin"], variable: "--font-space-grotesk" })

export const metadata: Metadata = {
  title: "Manga Inventory – Deine Sammlung. Immer im Blick.",
  description:
    "Manga-Sammlung verwalten: was im Regal steht, was gelesen ist, was doppelt ist und was noch fehlt. Mit Excel-Import und ISBN-Scanner.",
  icons: {
    icon: "/favicon.png",
    shortcut: "/favicon.png",
    apple: "/apple-icon.png",
  },
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
 return (
    <html lang="de" className={`${inter.variable} ${spaceGrotesk.variable}`}>
      <body className="font-sans antialiased">{children}</body>
    </html>
  )
} 
