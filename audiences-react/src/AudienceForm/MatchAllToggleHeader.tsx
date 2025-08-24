import { FlexItem, Toggle } from "playbook-ui"
import { Caption, Flex } from "playbook-ui"

import { MembersModalButton } from "./MembersModalButton"
import { useAudiencesContext } from "../audiences"

type MatchAllToggleHeaderProps = {
  allowMatchAll: boolean
}
export function MatchAllToggleHeader({ allowMatchAll }: MatchAllToggleHeaderProps) {
  const { value: context, isDirty, change } = useAudiencesContext()
  const handleToggle = () => change("match_all", !context.match_all)

  return (
    <Flex orientation="row" spacing="between" wrap>
      <FlexItem>
        <Caption text={`Members ${isDirty() ? "" : context.count}`} />
        {isDirty() ? (
          <Caption
            size="xs"
            marginTop="sm"
            text="Audience members will update when the page is saved"
          />
        ) : (
          <MembersModalButton
            text="View All"
            title="All Members"
            padding="none"
            total={context.count}
          />
        )}
      </FlexItem>
      {allowMatchAll && (
        <FlexItem>
          <Flex justify="right" orientation="row" align="center">
            <Toggle>
              <input
                type="checkbox"
                checked={context.match_all}
                onChange={handleToggle}
              />
            </Toggle>
            <Caption marginLeft="xs" size="xs" text={"All Employees"} />
          </Flex>
        </FlexItem>
      )}
    </Flex>
  )
}
