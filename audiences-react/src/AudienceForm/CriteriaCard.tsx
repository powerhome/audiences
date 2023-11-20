import { Card, Body, Flex, FlexItem, Caption } from "playbook-ui"

import type { GroupCriterion } from "../types"
import { CriteriaDescription } from "./CriteriaDescription"

type CriteriaFieldsProps = React.PropsWithChildren & {
  criterion?: GroupCriterion
}
export function CriteriaCard({ criterion, children }: CriteriaFieldsProps) {
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

        <FlexItem>{children}</FlexItem>
      </Flex>
    </Card>
  )
}
