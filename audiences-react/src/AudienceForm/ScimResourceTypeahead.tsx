import debounce from "lodash/debounce"
import { useController } from "react-hook-form"
import { Typeahead } from "playbook-ui"
import { ScimResourceType } from "../useScimResources"
import { AudienceResource } from "../types"
import get from "lodash/get"

interface ScimPhoto {
  type: "primary" | "thumb"
  value: string
}

interface ScimObject {
  id: string
  displayName: string
  photos?: [ScimPhoto]
}

type PlaybookOption = AudienceResource & {
  label: string
  value: any
  imageUrl?: string
}

function mapOptions(
  resource: ScimResourceType,
  objects: ScimObject[],
): PlaybookOption[] {
  return objects
    ? objects.map((object) => ({
        label: object.displayName,
        value: parseInt(object.id),
        imageUrl: get(object, "photos.0.value"),
        image_url: get(object, "photos.0.value"),
        display: object.displayName,
        resource_id: object.id,
        resource_type: resource.id,
      }))
    : []
}
function mapValues(objects: AudienceResource[]): PlaybookOption[] {
  return (
    objects?.map((object) => ({
      label: object.display,
      value: object.resource_id,
      imageUrl: object.image_url,
      ...object,
    })) || []
  )
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
      callback(mapOptions(resource, options))
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
      value={mapValues(field.value)}
    />
  )
}
