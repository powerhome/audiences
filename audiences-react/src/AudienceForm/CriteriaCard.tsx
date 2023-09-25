import { Card, Body, Flex, FlexItem, Caption } from "playbook-ui"

import type { AudienceCriteria } from "../types"

import { CriteriaDescription } from "./CriteriaDescription"
import { AudienceContextInput } from "."

type CriteriaFieldsProps = React.PropsWithChildren & {
  criteria?: AudienceContextInput["criteria"][0]
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
