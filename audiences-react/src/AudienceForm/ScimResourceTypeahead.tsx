import { debounce, get } from "lodash"
import { Typeahead } from "playbook-ui"

import Audiences from "../audiences"
import { ScimObject } from "../types"
import { useContext } from "react"

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

  const searchResourceOptions = async (
    search: string,
    callback: (options: PlaybookOption[]) => void,
  ) => {
    const options = await query(resourceId, search)
    callback(playbookOptions(options))
  }

  return (
    <Typeahead
      isMulti
      async
      loadOptions={searchResourceOptions}
      placeholder=""
      {...typeaheadProps}
      ref={undefined} // Warning: Function components cannot be given refs. Attempts to access this ref will fail. Did you mean to use React.forwardRef()?
      value={playbookOptions(value)}
      onChange={handleChange}
    />
  )
}
