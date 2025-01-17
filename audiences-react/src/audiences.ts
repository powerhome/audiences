import { createContext, useContext, useEffect } from "react"

import useFormReducer, {
  RegistryAction,
  UseFormReducer,
} from "./useFormReducer"
import { useFetch } from "./useFetch"
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
  query: (resourceId: string, displayName: string) => Promise<ScimObject[]>
  save: () => Promise<void>
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
  options: RequestInit = {},
): UseAudienceContext {
  const { get, put } = useFetch(uri, options)
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
    get<AudienceContext>(key)
      .then(criteriaForm.reset)
      .catch((error) => criteriaForm.setError(error.message))
  }, [key])

  async function fetchUsers(
    criterion?: GroupCriterion,
    search?: string,
    offset?: number,
  ) {
    return get<{ count: number; users: ScimObject[] }>(
      `${key}/users/${criterion?.id || ""}?offset=${offset}&search=${search}`,
    )
  }

  async function query(resourceId: string, displayName: string) {
    return await get<ScimObject[]>(`scim/${resourceId}?filter=${displayName}`)
  }

  async function save() {
    return put<AudienceContext>(key, criteriaForm.value)
      .then(criteriaForm.reset)
      .catch((error) => criteriaForm.setError(error.message))
  }

  return {
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
