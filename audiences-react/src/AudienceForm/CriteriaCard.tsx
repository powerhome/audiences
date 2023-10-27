import { Card, Body, Flex, FlexItem, Caption } from "playbook-ui"

import type { AudienceCriteria, GroupCriteria } from "../types"

import { CriteriaDescription } from "./CriteriaDescription"

type CriteriaFieldsProps = React.PropsWithChildren & {
  criteria?: GroupCriteria
}
export default function CriteriaCard({
  criteria,
  children,
}: CriteriaFieldsProps) {
  if (!criteria) {
    return null
  }

  return (
    <Card padding="xs" margin="xs">
      <Flex justify="between">
        <FlexItem>
          <Body className="mr-3">
            <CriteriaDescription criteria={criteria} />
          </Body>
          <Caption marginLeft="xs" size="xs" tag="span" text={criteria.count} />
        </FlexItem>

        <FlexItem>{children}</FlexItem>
      </Flex>
    </Card>
  )
}
