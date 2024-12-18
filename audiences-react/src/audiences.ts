import { createContext, useContext, useEffect } from "react"
import useFetch, { CachePolicies, IncomingOptions } from "use-http"

import useFormReducer, {
  RegistryAction,
  UseFormReducer,
} from "./useFormReducer"
import { AudienceContext, GroupCriterion, ScimObject } from "./types"
import { set } from "lodash/fp"

type RemoveCriteriaAction = RegistryAction & {
  index: number
}
type UpdateCriteriaAction = RegistryAction & {
  index: number
  criterion: GroupCriterion
}

export type UseAudienceContext = UseFormReducer<AudienceContext> & {
  loading: boolean
  query: <T>(resourceId: string, displayName: string) => Promise<T[]>
  save: () => void
  fetchUsers: (
    criterion?: GroupCriterion,
    search?: string,
    offset?: number,
  ) => Promise<{ count: number; users: ScimObject[] }>
  removeCriteria: (index: number) => void
  updateCriteria: (index: number, criteria: GroupCriterion) => void
}

export function useAudiences(
  uri: string,
  key: string,
  options: IncomingOptions = {},
): UseAudienceContext {
  const { get, put, response, loading } = useFetch(uri, {
    ...options,
    cachePolicy: CachePolicies.NO_CACHE,
  })
  const criteriaForm = useFormReducer<AudienceContext>({} as AudienceContext, {
    "remove-criteria": (
      context,
      _,
      action = _ as RemoveCriteriaAction,
    ): AudienceContext => ({
      ...context,
      criteria: [
        ...context.criteria.slice(0, action.index),
        ...context.criteria.slice(action.index + 1),
      ],
    }),
    "update-criteria": (
      context,
      _,
      action = _ as UpdateCriteriaAction,
    ): AudienceContext =>
      set(
        `criteria.${action.index}`,
        action.criterion,
        context,
      ) as AudienceContext,
  })
  useEffect(() => {
    get(key).then(criteriaForm.reset)
  }, [key])

  async function fetchUsers(
    criterion?: GroupCriterion,
    search?: string,
    offset?: number,
  ) {
    return get(
      `/${key}/users/${criterion?.id || ""}?offset=${offset}&search=${search}`,
    )
  }

  async function query(resourceId: string, displayName: string) {
    return await get(`/scim/${resourceId}?filter=${displayName}`)
  }

  async function save() {
    const updatedContext = await put(key, criteriaForm.value)
    if (response.ok) {
      criteriaForm.reset(updatedContext)
    } else {
      criteriaForm.setError("Unhandled server error")
    }
  }

  return {
    loading,
    fetchUsers,
    save,
    query,
    ...criteriaForm,
    removeCriteria: (index: number) =>
      criteriaForm.dispatch({ type: "remove-criteria", index }),
    updateCriteria: (index: number, criterion: GroupCriterion) =>
      criteriaForm.dispatch({ type: "update-criteria", index, criterion }),
  }
}

const Context = createContext<UseAudienceContext | undefined>(undefined)
export function useAudiencesContext() {
  return useContext(Context)!
}
export default Context
