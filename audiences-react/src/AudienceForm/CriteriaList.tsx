import { Button, Flex, FlexItem } from "playbook-ui"
import { useFormContext } from "react-hook-form"

import { GroupCriterion } from "../types"

import { CriteriaCard } from "./CriteriaCard"

type CriteriaListFieldsProps = {
  addCriteriaLabel: string
  onAddCriteria: () => void
  onRemoveCriteria: (index: number) => void
  onEditCriteria: (index: number) => void
}
export function CriteriaList({ addCriteriaLabel, onAddCriteria, onRemoveCriteria, onEditCriteria }: CriteriaListFieldsProps) {
  const { watch, getFieldState } = useFormContext()
  const currentCriteria = (watch("criteria") || []) as GroupCriterion[]
  const isCriterionDirty = (index: number) => getFieldState(`criteria.${index}`).isDirty

  return (
    <Flex orientation="column" align="stretch">
      {currentCriteria.map(
        (criterion, index: number) => (
          <CriteriaCard
            key={`criterion-${criterion.id}`}
            criterion={criterion}
            viewUsers={!isCriterionDirty(index)}
            onRequestEdit={() => onEditCriteria(index)}
            onRequestRemove={() => onRemoveCriteria(index)}
          />
        ),
      )}

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
