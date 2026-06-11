const BACKEND_URL = process.env.API_URL
const API_KEY = process.env.API_KEY

export async function backendFetch(path: string, init?: RequestInit) {
  const res = await fetch(`${BACKEND_URL}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      "X-API-Key": API_KEY ?? "",
      ...(init?.headers as Record<string, string> | undefined),
    },
  })
  return res
}
