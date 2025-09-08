import { debounce, get } from "lodash"
import { Typeahead, Title, User } from "playbook-ui"
import { useContext, useEffect, useRef } from "react"

import Audiences from "../audiences"
import { ScimObject } from "../types"

type PlaybookOption = ScimObject & {
  value: any
  label: string
  imageUrl?: string
}

function playbookOptions(objects: ScimObject[]): PlaybookOption[] {
  console.log("the obj", objects)
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
  isMobile?: boolean
}
export function ScimResourceTypeahead({
  resourceId,
  onChange,
  value,
  isMobile,
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
      <>
    <Typeahead
      isMulti
      async
      loadOptions={loadOptions}
      placeholder=""
      {...typeaheadProps}
      value={playbookOptions(value)}
      onChange={handleChange}
    />
      {isMobile && value && value.map(user => {
        const extension = user["urn:ietf:params:scim:schemas:extension:authservice:2.0:User"] || {}
        return (
          <User
              key={user.id}
              align="left"
              avatarUrl={get(user, "photos.0.value")}
              name={user.displayName}
              orientation="horizontal"
              territory={extension.territoryAbbr}
              title={user.title}
              marginBottom="sm"
          />
        )
      })}
    </>
  )
}
