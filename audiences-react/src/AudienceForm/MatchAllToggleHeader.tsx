import { FlexItem, Toggle } from "playbook-ui"
import { ReactNode } from "react"
import { Card, Caption, Flex } from "playbook-ui"

import { MembersModalButton } from "./MembersModalButton"
import { useAudiences } from "../audiences"

type MatchAllToggleCardProps = {
  children: ReactNode
  count: number
  enabled: boolean
  fetchUsers: ReturnType<typeof useAudiences>["fetchUsers"]
  isDirty: boolean
  onToggle: (all: boolean) => void
}
export function MatchAllToggleCard({
  children,
  count,
  enabled,
  fetchUsers,
  isDirty,
  onToggle,
}: MatchAllToggleCardProps) {
  return (
    <Card margin="xs" padding="xs">
      <Card.Header headerColor={enabled ? "none" : "white"}>
        <Flex orientation="row" spacing="between" wrap>
          <FlexItem>
            <Caption text={`Members ${isDirty ? "" : count}`} />
            {isDirty ? (
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
                fetchUsers={fetchUsers}
                total={count}
              />
            )}
          </FlexItem>
          <FlexItem>
            <Flex justify="right" orientation="row" align="center">
              <Toggle>
                <input
                  type="checkbox"
                  checked={enabled}
                  onChange={() => onToggle(!enabled)}
                />
              </Toggle>
              <Caption marginLeft="xs" size="xs" text={"All Employees"} />
            </Flex>
          </FlexItem>
        </Flex>
      </Card.Header>

      <Card.Body>
        <Flex orientation="column" align="stretch">
          {children}
        </Flex>
      </Card.Body>
    </Card>
  )
}
