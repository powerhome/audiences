import { useFetch } from "use-http"

export type ScimListResponse<T> = {
  totalEntries: number
  Resources: T[]
}

export type ScimResourceType = {
  id: string
  name: string
  endpoint: string
  filter: <T>(displayName: string) => Promise<T[]>
}

type UseScimResources = {
  resources?: ScimResourceType[]
}
export function useScimResources(scimUri: string): UseScimResources {
  const { get } = useFetch(scimUri)
  const { data } = useFetch<ScimResourceType[]>(
    `${scimUri}/ResourceTypes`,
    {},
    [],
  )

  if (!data) {
    return {}
  }

  const filter =
    (resource: ScimResourceType) => async (displayName: string) => {
      const response = await get(
        `${resource.endpoint}?filter=displayName co ${displayName}`,
      )
      return response.Resources
    }

  return {
    resources: data.map((r) => ({ ...r, filter: filter(r) })),
  }
}
