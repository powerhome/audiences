import { Button, Flex, FlexItem } from "playbook-ui"
import { AudienceContext } from "../types"
import { CriteriaCard } from "./CriteriaCard"
import { useAudiences } from "../audiences"

type CriteriaListProps = {
  addCriteriaLabel: string
  context: AudienceContext
  onAddCriteria: () => void
  onEditCriteria: (index: number) => void
  onRemoveCriteria: (index: number) => void
}
export function CriteriaList({
  context,
  addCriteriaLabel,
  onAddCriteria,
  onRemoveCriteria,
  onEditCriteria,
}: CriteriaListProps) {
  return (
    <Flex orientation="column" align="stretch">
      {context.criteria.map((criterion, index: number) => (
        <CriteriaCard
          criterion={criterion}
          key={`criterion-${index}`}
          onRequestEdit={() => onEditCriteria(index)}
          onRequestRemove={() => onRemoveCriteria(index)}
          viewUsers={criterion.count !== undefined}
        />
      ))}

      <FlexItem alignSelf="center">
        <Button
          fixedWidth
          marginTop="md"
          onClick={onAddCriteria}
          text={addCriteriaLabel}
          variant="link"
        />
      </FlexItem>
    </Flex>
  )
}
