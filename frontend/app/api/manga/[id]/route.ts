import { type NextRequest, NextResponse } from "next/server"
import { backendFetch } from "../_proxy"

export async function GET(_request: NextRequest, { params }: { params: { id: string } }) {
  const res = await backendFetch(`/api/manga/${params.id}`)
  const data = await res.json()
  return NextResponse.json(data, { status: res.status })
}

export async function PUT(request: NextRequest, { params }: { params: { id: string } }) {
  const body = await request.json()
  const res = await backendFetch(`/api/manga/${params.id}`, {
    method: "PUT",
    body: JSON.stringify(body),
  })
  const data = await res.json()
  return NextResponse.json(data, { status: res.status })
}

export async function DELETE(_request: NextRequest, { params }: { params: { id: string } }) {
  const res = await backendFetch(`/api/manga/${params.id}`, { method: "DELETE" })
  const data = await res.json()
  return NextResponse.json(data, { status: res.status })
}
