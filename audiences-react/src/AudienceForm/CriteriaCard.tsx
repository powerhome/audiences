import { Card, Body, Flex, FlexItem, Caption } from "playbook-ui"

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
  if (!criterion) {
    return null
  }

  return (
    <Card padding="xs" margin="xs">
      <Flex justify="between">
        <FlexItem>
          <Body className="mr-3">
            <CriteriaDescription groups={criterion.groups} />
          </Body>
          {viewUsers && (
            <Caption
              marginLeft="xs"
              size="xs"
              tag="span"
              text={`Members ${criterion.count?.toString()}`}
            />
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
