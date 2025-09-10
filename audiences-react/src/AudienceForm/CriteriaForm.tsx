import { Button, Card, Flex, IconValue } from "playbook-ui"
import { flatten, isEmpty, keyBy, mapValues, values } from "lodash"

import { CriteriaDescription } from "./CriteriaDescription"
import { ScimResourceTypeahead } from "./ScimResourceTypeahead"
import { GroupCriterion } from "../types"
import { useAudiencesContext } from "../audiences"
import useFormReducer from "../useFormReducer"

export type CriteriaFormProps = {
  resources: string[]
  criterion: number
  isMobile?: boolean
  onSkip?: () => void
  onExit: () => void
}
function buildCriterion(resources: string[]) {
  const emptyGroups = mapValues(keyBy(resources), () => [])
  return { groups: emptyGroups }
}
export function CriteriaForm({
  resources,
  criterion,
  isMobile,
  onSkip,
  onExit,
}: CriteriaFormProps) {
  const { value: context, updateCriteria, reset } = useAudiencesContext()
  const { value, change } = useFormReducer<GroupCriterion>(
    context.criteria[criterion] || buildCriterion(resources),
  )

  const emptyCriteria = isEmpty(flatten(values(value.groups)))

  const handleSave = () => {
    updateCriteria(criterion, value)
    onExit()
  }

  const handleCancel = () => {
   onExit()
  }

  const handleClose = () => {
    onSkip ? onSkip() : onExit()
  }

  return (
    <Card paddingX={isMobile && "sm"} borderNone={isMobile}>
      <Card.Header paddingX={isMobile && "xs"} headerColor="white">
        <Button onClick={handleCancel} variant="link" padding="none">
          <IconValue
            fixedWidth
            icon="chevron-left"
            align="left"
            size="1x"
            text="Filter Members"
          />
        </Button>
      </Card.Header>

      <Card.Body paddingX={isMobile && "xs"}>
        {resources.map((resourceId) => (
          <ScimResourceTypeahead
            resourceId={resourceId}
            key={`criterion.groups.${resourceId}`}
            label={resourceId}
            value={value.groups[resourceId]}
            onChange={(values) => change(`groups.${resourceId}`, values)}
          />
        ))}

        {emptyCriteria || <CriteriaDescription groups={value.groups} />}
        {isMobile ? (
          <Flex orientation="column" align="center" marginTop="md">
            <Button
              fullWidth
              onClick={handleSave}
              text="Save"
              disabled={emptyCriteria}
            />
            <Button
              fullWidth
              marginTop="xs"
              onClick={handleClose}
              text="Skip for now"
              variant="secondary"
            />
          </Flex>
        ) : (
          <Flex justify="between" marginTop="md">
            <Button onClick={handleSave} text="Save" disabled={emptyCriteria} />
            <Button onClick={handleCancel} text="Cancel" variant="link" />
          </Flex>
        )}
      </Card.Body>
    </Card>
  )
}
