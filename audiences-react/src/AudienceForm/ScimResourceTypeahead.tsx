import debounce from "lodash/debounce"
import { useController } from "react-hook-form"
import { Typeahead } from "playbook-ui"
import { ScimResourceType } from "../useScimResources"
import { ScimObject } from "../types"
import get from "lodash/get"

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

export interface ScimResourceTypeahead {
  name: string
  resource: ScimResourceType
  valueComponent?: any
  label: string
}
export default function ScimResourceTypeahead({
  name,
  resource,
  ...typeaheadProps
}: ScimResourceTypeahead) {
  const { field } = useController({ name })

  const searchResourceOptions = async (
    search: string,
    callback: (options: PlaybookOption[]) => void,
  ) => {
    if (search.length > 0) {
      const options = await resource.filter<ScimObject>(search)
      callback(playbookOptions(options))
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
    />
  )
}
