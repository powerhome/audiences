import { Card, Flex, FlexItem, Caption } from "playbook-ui"
import { isEmpty } from "lodash"

import type { GroupCriterion } from "../types"
import { CriteriaDescription } from "./CriteriaDescription"
import { CriteriaActions } from "./CriteriaActions"
import { useAudiences } from "../audiences"

type CriteriaCardProps = {
  criterion?: GroupCriterion
  fetchUsers: ReturnType<typeof useAudiences>["fetchUsers"]
  onRequestEdit: () => void
  onRequestRemove: () => void
  viewUsers: boolean
}
export function CriteriaCard({
  criterion,
  fetchUsers,
  viewUsers,
  onRequestRemove,
  onRequestEdit,
}: CriteriaCardProps) {
  if (!criterion || isEmpty(criterion.groups)) {
    return null
  }

  return (
    <Card padding="sm" marginBottom="xs">
      <Flex justify="between">
        <FlexItem>
          <CriteriaDescription groups={criterion.groups} />
          {viewUsers && (
            <Caption text={`Members ${criterion.count?.toString()}`} />
          )}
        </FlexItem>

        <FlexItem>
          <CriteriaActions
            criterion={criterion}
            fetchUsers={fetchUsers}
            onRequestRemove={onRequestRemove}
            onRequestEdit={onRequestEdit}
            viewUsers={viewUsers}
          />
        </FlexItem>
      </Flex>
    </Card>
  )
}
