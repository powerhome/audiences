import { useState, useEffect, useContext } from "react"
import { CachePolicies, UseFetchObjectReturn, useFetch } from "use-http"

import { AudienceContext, GroupCriterion, ScimObject } from "./types"
import { createContext } from "react"

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type ContextProps = UseFetchObjectReturn<any> & {
  context?: AudienceContext
  setContext: (newContext: AudienceContext) => void
}

const Context = createContext<ContextProps | undefined>(undefined)

export function useAudience(uri: string): ContextProps {
  const [context, setContext] = useState<AudienceContext | undefined>()
  const fetch = useFetch(uri, {
    cachePolicy: CachePolicies.NO_CACHE,
    onError({ error }) {
      throw error.message
    },
  })

  useEffect(
    function () {
      fetch.get().then(setContext)
    },
    [uri],
  )

  return { context, setContext, ...fetch }
}

type UseAudienceContext = {
  context?: AudienceContext
  update: (attrs: AudienceContext) => void
  fetchUsers: (criterion?: GroupCriterion) => Promise<ScimObject[]>
}
export function useAudienceContext(): UseAudienceContext {
  const { context, setContext, get, put } = useContext(Context)!

  async function fetchUsers(criterion?: GroupCriterion) {
    return get(`/users/${criterion?.id || ""}`)
  }

  async function update(attrs: AudienceContext) {
    try {
      const updatedContext = await put(attrs)
      setContext(updatedContext)
    } catch (e) {
      console.log(attrs, e)
    }
  }

  return { context, update, fetchUsers }
}

export default Context
