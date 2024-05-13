import { createContext, useContext } from "react"
import { useFetch } from "use-http"

const Context = createContext<string>("")

type UseScimResources = {
  filter: <T>(resourceId: string, displayName: string) => Promise<T[]>
}
export function useScim(): UseScimResources {
  const uri = useContext(Context)
  const { get } = useFetch(uri)

  const filter = async (resourceId: string, displayName: string) => {
    return await get(`${resourceId}?filter=displayName co "${displayName}"`)
  }

  return { filter }
}

export default Context
