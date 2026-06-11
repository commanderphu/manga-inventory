import { type NextRequest, NextResponse } from "next/server"
import { backendFetch } from "./_proxy"

export async function GET(request: NextRequest) {
  const { search } = new URL(request.url)
  const res = await backendFetch(`/api/manga${search}`)
  const data = await res.json()
  return NextResponse.json(data, { status: res.status })
}

export async function POST(request: NextRequest) {
  const body = await request.json()
  const res = await backendFetch("/api/manga", {
    method: "POST",
    body: JSON.stringify(body),
  })
  const data = await res.json()
  return NextResponse.json(data, { status: res.status })
}
