import { debounce, get } from "lodash"
import { Typeahead, User, IconButton, Flex, FlexItem } from "playbook-ui"
import { useContext, useEffect, useRef } from "react"
import { components, SingleValueProps, OptionProps } from "react-select"
import Audiences from "../audiences"
import { ScimObject } from "../types"

/**
 * @description This has to be hardcoded because the API returns an object where the key for the user details
 * can only be accessed using this SCIM_USER_KEY constant. We should update this later.
 */
const SCIM_USER_KEY =
  "urn:ietf:params:scim:schemas:extension:authservice:2.0:User" as const

type PlaybookOption = ScimObject & {
  value: number
  label: string
}

function playbookOptions(
  objects: ScimObject[],
  isMobile?: boolean,
): PlaybookOption[] {
  return objects
    ? objects.map((object: ScimObject) => ({
        ...object,
        value: parseInt(object.id),
        label: object.displayName,
        imageUrl: !isMobile && get(object, "photos.0.value"),
      }))
    : []
}

type UsersTypeaheadProps = {
  label: string
  value: ScimObject[]
  onChange: (values: ScimObject[]) => void
  resourceId: string
  isMobile?: boolean
}
export function UsersTypeahead({
  resourceId,
  onChange,
  value,
  isMobile,
  ...typeaheadProps
}: UsersTypeaheadProps) {
  const { query } = useContext(Audiences)!

  function handleChange(value: any, ...event: any[]) {
    onChange(value || [])
  }

  const debouncedFetchOptions = useRef(
    debounce(
      async (search: string, callback: (options: PlaybookOption[]) => void) => {
        const options = await query(resourceId, search)
        callback(playbookOptions(options, isMobile))
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

  const formatOptionLabel = (user: ScimObject) => {
    const extension =
      user[SCIM_USER_KEY] || ({} as ScimObject[typeof SCIM_USER_KEY])
    return (
      <User
        align="left"
        avatarUrl={get(user, "photos.0.value")}
        name={user.displayName}
        orientation="horizontal"
        territory={extension?.territoryAbbr}
        title={user.title}
      />
    )
  }

  const customComponents = {
    Option: (highlightProps: OptionProps<PlaybookOption, true>) => (
      <components.Option {...highlightProps} />
    ),
    SingleValue: (props: SingleValueProps<PlaybookOption, true>) => (
      <components.SingleValue {...props}>
        <span>{props.data.displayName}</span>
      </components.SingleValue>
    ),
  }

  return (
    <>
      <Typeahead
        components={customComponents}
        formatOptionLabel={formatOptionLabel}
        isMulti
        multiKit="smallPill"
        truncate={1}
        async
        loadOptions={loadOptions}
        placeholder=""
        {...typeaheadProps}
        value={playbookOptions(value, isMobile)}
        onChange={handleChange}
      />
      {isMobile &&
        value &&
        value.map((user: ScimObject) => {
          // NOTE: This is a workaround for the SCIM API's structure
          const extension =
            user[SCIM_USER_KEY] || ({} as ScimObject[typeof SCIM_USER_KEY])
          const handleRemoveUser = () => {
            const newValue = value.filter((u) => u.id !== user.id)
            onChange(newValue)
          }
          return (
            <Flex justify="between" key={user.id} marginBottom="sm">
              <FlexItem>
                <User
                  align="left"
                  avatarUrl={get(user, "photos.0.value")}
                  name={user.displayName}
                  orientation="horizontal"
                  territory={extension?.territoryAbbr}
                  title={user.title}
                />
              </FlexItem>
              <FlexItem>
                <IconButton
                  onClick={handleRemoveUser}
                  icon="xmark"
                  size="sm"
                  color="default"
                ></IconButton>
              </FlexItem>
            </Flex>
          )
        })}
    </>
  )
}
