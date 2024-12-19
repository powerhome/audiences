import { useCallback } from "react"

async function handleJsonResponse(response: Response) {
  if (response.ok) {
    return response.json()
  } else {
    throw new Error(response.statusText)
  }
}

async function doFetch(base: string, path: string, options: RequestInit = {}) {
  return fetch(`${base}/${path}`, options).then(handleJsonResponse)
}

export function useFetch(uri: string, options: RequestInit = {}) {
  const get = useCallback(<T>(path: string): Promise<T> => {
    return doFetch(uri, path, options)
  }, [uri, options])
  const put = useCallback(<T>(path: string, data: any): Promise<T> => {
    return doFetch(uri, path, {
      method: "PUT",
      body: JSON.stringify(data),
      ...options,
      headers: { "Content-Type": "application/json", ...options.headers },
    })
  }, [uri, options])

  return { get, put }
}
