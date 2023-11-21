import { useState, useEffect } from "react"
import { useFetch } from "use-http"

import { AudienceContext } from "./types"

type UseAudience = {
  context: AudienceContext | undefined
  update: (attrs: AudienceContext) => void
}
export function useAudience(uri: string): UseAudience {
  const [context, setContext] = useState<AudienceContext>()
  const { get, put } = useFetch(uri, {
    onError({ error }) {
      throw error.message
    },
  })
  useEffect(() => {
    get().then(setContext)
  }, [])

  async function update(attrs: AudienceContext) {
    try {
      const updatedContext = await put(attrs)
      setContext(updatedContext)
    } catch (e) {
      console.log(context, e)
    }
  }

  return { context, update }
}
