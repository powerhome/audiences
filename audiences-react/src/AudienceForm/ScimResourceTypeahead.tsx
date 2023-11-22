import debounce from "lodash/debounce"
import { useController } from "react-hook-form"
import get from "lodash/get"
import { Typeahead } from "playbook-ui"
import { useScim } from "../scim"
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
  name: string
  resourceId: string
}
export function ScimResourceTypeahead({
  name,
  resourceId,
  ...typeaheadProps
}: ScimResourceTypeaheadProps) {
  const { field } = useController({ name })
  const { filter } = useScim()

  function onChange(value: any, ...event: any[]) {
    field.onChange(value || [], ...event)
  }

  const searchResourceOptions = async (
    search: string,
    callback: (options: PlaybookOption[]) => void,
  ) => {
    if (search.length > 2) {
      const options = await filter<ScimObject>(resourceId, search)
      callback(playbookOptions(options))
    } else {
      callback([])
    }
  }

  return (
    <Typeahead
      isMulti
      async
      loadOptions={debounce(searchResourceOptions, 600)}
      placeholder=""
      {...typeaheadProps}
      {...field}
      ref={undefined} // Warning: Function components cannot be given refs. Attempts to access this ref will fail. Did you mean to use React.forwardRef()?
      value={playbookOptions(field.value)}
      onChange={onChange}
    />
  )
}
