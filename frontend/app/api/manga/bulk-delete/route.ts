import { type NextRequest, NextResponse } from "next/server"
import { backendFetch } from "../_proxy"

export async function DELETE(request: NextRequest) {
  const { ids }: { ids: string[] } = await request.json()

  if (!Array.isArray(ids) || ids.length === 0) {
    return NextResponse.json({ error: "Invalid or empty ids array" }, { status: 400 })
  }

  await Promise.all(
    ids.map((id) => backendFetch(`/api/manga/${id}`, { method: "DELETE" }))
  )

  return NextResponse.json({ message: `${ids.length} manga deleted successfully` })
}
