import { FlexItem, Toggle, Button } from "playbook-ui"
import { Caption, Flex } from "playbook-ui"

import { MembersModal } from "./MembersModal"
import { useAudiencesContext } from "../audiences"
import { useState } from "react"

type MatchAllToggleHeaderProps = {
  allowMatchAll: boolean
  isMobile?: boolean
}
export function MatchAllToggleHeader({
  allowMatchAll,
  isMobile,
}: MatchAllToggleHeaderProps) {
  const { value: context, isDirty, change } = useAudiencesContext()
  const handleToggle = () => change("match_all", !context.match_all)
  const [showMembers, setShowMembers] = useState(false)

  return (
    <>
      <Flex orientation={isMobile ? "column" : "row"} spacing="between" wrap>
        <FlexItem>
          <Caption text={`Members ${isDirty() ? "" : context.count}`} />
          {isDirty() ? (
            <Caption
              size="xs"
              marginTop="sm"
              text="Save changes to view all members"
            />
          ) : (
            <Button
              variant="link"
              padding="none"
              onClick={() => setShowMembers(true)}
              text="View All"
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
      <MembersModal
        title="All Members"
        total={context.count}
        showMembers={showMembers}
        setShowMembers={setShowMembers}
      />
    </>
  )
}
