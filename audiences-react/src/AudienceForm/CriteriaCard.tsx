import { Card, Flex, FlexItem, Caption } from "playbook-ui"
import { isEmpty } from "lodash"
import { useState } from "react"

import type { GroupCriterion } from "../types"
import { CriteriaDescription } from "./CriteriaDescription"
import { CriteriaActions } from "./CriteriaActions"
import { useAudiences } from "../audiences"

type CriteriaCardProps = {
  criterion?: GroupCriterion
  onRequestEdit: () => void
  onRequestRemove: () => void
  viewUsers: boolean
}
export function CriteriaCard({
  criterion,
  viewUsers,
  onRequestRemove,
  onRequestEdit,
}: CriteriaCardProps) {
  const [showPopover, setShowPopover] = useState(false)

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
            showPopover={showPopover}
            setShowPopover={setShowPopover}
          />
        </FlexItem>
      </Flex>
    </Card>
  )
}
