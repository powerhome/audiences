import { createContext, useContext, useEffect, useState } from "react"

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
  saving: boolean
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
  options: RequestInit = {},
): UseAudienceContext {
  const [ saving, setSaving ] = useState(false)
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
    get(key).then(criteriaForm.reset)
  }, [key])

  async function fetchUsers(
    criterion?: GroupCriterion,
    search?: string,
    offset?: number,
  ) {
    return get(
      `${key}/users/${criterion?.id || ""}?offset=${offset}&search=${search}`,
    )
  }

  async function query(resourceId: string, displayName: string) {
    return await get(`scim/${resourceId}?filter=${displayName}`)
  }

  async function save() {
    setSaving(true)
    return put(key, criteriaForm.value)
        .then((response: AudienceContext) => criteriaForm.reset(response))
        .catch((error: Error) => criteriaForm.setError(error.message))
        .finally(() => setSaving(false))
  }

  return {
    saving,
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
