import { get, isEqual } from "lodash"
import { set } from "lodash/fp"
import { useState, useReducer, useCallback } from "react"

export interface RegistryAction {
  type: string
}
type ErrorAction = RegistryAction & { message: string }
type ResetAction<T> = RegistryAction & { state: FormState<T> }
type ChangeAction = RegistryAction & { name: string; value: any } // eslint-disable-line @typescript-eslint/no-explicit-any
type ReducerAction<T> = (
  value: FormState<T>,
  action: RegistryAction,
) => FormState<T>
type NestedReducerAction<T> = (value: T, action: RegistryAction) => T
type NestedReducerRegistry<T> = Record<string, NestedReducerAction<T>>
export type FormState<T> = {
  error?: string | undefined
  value: T
}

const DefaultFormReducers = {
  change<T>(state: FormState<T>, action: ChangeAction): FormState<T> {
    const value = set(action.name, action.value, state.value as object) as T
    return { ...state, value }
  },
  reset<T>(_: FormState<T>, action: ResetAction<T>): FormState<T> {
    return action.state
  },
  error<T>(state: FormState<T>, action: ErrorAction): FormState<T> {
    return { ...state, error: action.message }
  },
}

const form = {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  change(name: string, value: any): ChangeAction {
    return { type: "change", name, value }
  },
  reset<T>(state: FormState<T>): ResetAction<T> {
    return { type: "reset", state }
  },
  error<T>(message: string): ErrorAction {
    return { type: "error", message }
  },
  reducer<T>(nestedReducers?: NestedReducerRegistry<T>): ReducerAction<T> {
    return (state: FormState<T>, action: RegistryAction) => {
      if (action.type in DefaultFormReducers) {
        return get(DefaultFormReducers, action.type)(state, action)
      } else if (nestedReducers && action.type in nestedReducers) {
        const value = get(nestedReducers, action.type)(state.value, action)
        return { ...state, value }
      }
    }
  },
}

export type UseFormReducer<T> = FormState<T> & {
  isDirty: (attribute?: string) => boolean
  dispatch: ReturnType<typeof useReducer>[1]
  reset: (newInitial?: T) => void
  setError: (message: string) => void
  change: (name: string, value: any) => void // eslint-disable-line @typescript-eslint/no-explicit-any
}
export default function useFormReducer<T>(
  initial: T,
  nestedReducer?: NestedReducerRegistry<T>,
): UseFormReducer<T> {
  const [initialValue, setInitialValue] = useState<T>(initial)
  const [state, dispatch] = useReducer(form.reducer(nestedReducer), {
    value: initialValue,
  })

  const isDirty = useCallback(
    (attribute?: string) => {
      if (attribute) {
        return !isEqual(
          get(initialValue, attribute),
          get(state.value, attribute),
        )
      } else {
        return !isEqual(initialValue, state.value)
      }
    },
    [initialValue, state.value],
  )
  const reset = (newInitial?: T) => {
    if (newInitial) {
      setInitialValue(newInitial)
      dispatch(form.reset({ value: newInitial }))
    } else {
      dispatch(form.reset({ value: initialValue }))
    }
  }

  return {
    ...state,
    isDirty,
    dispatch,
    reset,
    setError(message: string) {
      dispatch(form.error(message))
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    change(name: string, value: any) {
      dispatch(form.change(name, value))
    },
  }
}
