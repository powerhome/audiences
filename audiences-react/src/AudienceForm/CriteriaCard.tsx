import { Card, Flex, FlexItem, Caption } from "playbook-ui"
import isEmpty from "lodash/isEmpty"

import type { GroupCriterion } from "../types"
import { CriteriaDescription } from "./CriteriaDescription"
import { CriteriaActions } from "./CriteriaActions"

type CriteriaCardProps = {
  viewUsers: boolean
  criterion?: GroupCriterion
  onRequestRemove: () => void
  onRequestEdit: () => void
}
export function CriteriaCard({
  criterion,
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
            onRequestRemove={onRequestRemove}
            onRequestEdit={onRequestEdit}
            viewUsers={viewUsers}
          />
        </FlexItem>
      </Flex>
    </Card>
  )
}
