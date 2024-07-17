import { get, isEqual } from "lodash"
import { set } from "lodash/fp"
import { useState, useReducer, useCallback } from "react"

export interface RegistryAction {
  type: string
}
type ResetAction<T> = RegistryAction & { value: T }
type ChangeAction = RegistryAction & { name: string; value: any } // eslint-disable-line @typescript-eslint/no-explicit-any
type ReducerAction<T> = (value: T, action: RegistryAction) => T
type ReducerRegistry<T> = Record<string, ReducerAction<T>>

const DefaultFormReducers = {
  change<T>(value: T, action: ChangeAction): T {
    return set(action.name, action.value, value as object) as T
  },
  reset<T>(_: T, action: ResetAction<T>) {
    return action.value
  },
}

const form = {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  change(name: string, value: any): ChangeAction {
    return { type: "change", name, value }
  },
  reset<T>(value: T): ResetAction<T> {
    return { type: "reset", value }
  },
  reducer<T>(nestedReducers?: ReducerRegistry<T>): ReducerAction<T> {
    return (value: T, action: RegistryAction) => {
      const reducer =
        get(DefaultFormReducers, action.type) ||
        get(nestedReducers, action.type)

      if (reducer) {
        return reducer(value, action)
      }
    }
  },
}

export type UseFormReducer<T> = {
  isDirty: (attribute?: string) => boolean
  value: T
  dispatch: ReturnType<typeof useReducer>[1]
  reset: (newInitial?: T) => void
  change: (name: string, value: any) => void // eslint-disable-line @typescript-eslint/no-explicit-any
}
export default function useFormReducer<T>(
  initial: T,
  nestedReducer?: ReducerRegistry<T>,
): UseFormReducer<T> {
  const [initialValue, setInitialValue] = useState<T>(initial)
  const [value, dispatch] = useReducer(
    form.reducer(nestedReducer),
    initialValue,
  )

  const isDirty = useCallback(
    (attribute?: string) => {
      if (attribute) {
        return !isEqual(get(initialValue, attribute), get(value, attribute))
      } else {
        return !isEqual(initialValue, value)
      }
    },
    [initialValue, value],
  )
  const reset = (newInitial?: T) => {
    if (newInitial) {
      setInitialValue(newInitial)
      dispatch(form.reset(newInitial))
    } else {
      dispatch(form.reset(initialValue))
    }
  }

  return {
    isDirty,
    value,
    dispatch,
    reset,
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    change(name: string, value: any) {
      dispatch(form.change(name, value))
    },
  }
}
