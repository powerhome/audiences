import { Card, Body, Flex, FlexItem, Caption } from "playbook-ui"

import type { GroupCriterion } from "../types"
import { CriteriaDescription } from "./CriteriaDescription"
import { CriteriaActions } from "./CriteriaActions"

type CriteriaFieldsProps = {
  criterion?: GroupCriterion
  onRequestRemove: () => void
  onRequestEdit: () => void
  onRequestViewMembers: () => void
}
export function CriteriaCard({
  criterion,
  onRequestRemove,
  onRequestEdit,
  onRequestViewMembers,
}: CriteriaFieldsProps) {
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
          <Caption
            marginLeft="xs"
            size="xs"
            tag="span"
            text={criterion.count?.toString()}
          />
        </FlexItem>

        <FlexItem>
          <CriteriaActions
            criterion={criterion}
            onRequestRemove={onRequestRemove}
            onRequestEdit={onRequestEdit}
          />
        </FlexItem>
      </Flex>
    </Card>
  )
}
