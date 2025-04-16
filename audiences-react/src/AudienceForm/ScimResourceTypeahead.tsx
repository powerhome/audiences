import { debounce, get } from "lodash"
import { Typeahead } from "playbook-ui"
import { useContext, useEffect, useRef } from "react"

import Audiences from "../audiences"
import { ScimObject } from "../types"

type PlaybookOption = ScimObject & {
  value: any
  label: string
  imageUrl?: string
}

function playbookOptions(objects: ScimObject[]): PlaybookOption[] {
  return objects
    ? objects.map((object: ScimObject) => ({
        ...object,
        value: parseInt(object.id),
        label: object.displayName,
        imageUrl: get(object, "photos.0.value"),
      }))
    : []
}

type ScimResourceTypeaheadProps = {
  label: string
  value: ScimObject[]
  onChange: (values: ScimObject[]) => void
  resourceId: string
}
export function ScimResourceTypeahead({
  resourceId,
  onChange,
  value,
  ...typeaheadProps
}: ScimResourceTypeaheadProps) {
  const { query } = useContext(Audiences)!

  function handleChange(value: any, ...event: any[]) {
    onChange(value || [])
  }

  const debouncedFetchOptions = useRef(
    debounce(
      async (search: string, callback: (options: PlaybookOption[]) => void) => {
        const options = await query(resourceId, search)
        callback(playbookOptions(options))
      },
      600,
    ),
  ).current

  useEffect(() => {
    return () => {
      debouncedFetchOptions.cancel()
    }
  }, [debouncedFetchOptions])

  const loadOptions = (
    search: string,
    callback: (options: PlaybookOption[]) => void,
  ) => {
    debouncedFetchOptions(search, callback)
  }

  return (
    <Typeahead
      isMulti
      async
      loadOptions={loadOptions}
      placeholder=""
      {...typeaheadProps}
      value={playbookOptions(value)}
      onChange={handleChange}
    />
  )
}
