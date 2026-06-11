import { NextResponse } from "next/server"
import { backendFetch } from "../../_proxy"

export async function GET() {
  const res = await backendFetch("/api/manga/stats/summary")
  const data = await res.json()
  return NextResponse.json(data, { status: res.status })
}
