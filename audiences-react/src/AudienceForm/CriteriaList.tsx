import { Flex } from "playbook-ui"
import { CriteriaCard } from "./CriteriaCard"
import { useAudiencesContext } from "../audiences"

type CriteriaListProps = {
  onEditCriteria: (index: number) => void
}
export function CriteriaList({ onEditCriteria }: CriteriaListProps) {
  const { value: context, removeCriteria } = useAudiencesContext()

  const handleRemoveCriteria = (index: number) => {
    if (confirm("Remove criteria?")) {
      removeCriteria(index)
    }
  }

  return (
    <Flex orientation="column" align="stretch">
      {context.criteria.map((criterion, index: number) => (
        <CriteriaCard
          criterion={criterion}
          key={`criterion-${index}`}
          onRequestEdit={() => onEditCriteria(index)}
          onRequestRemove={() => handleRemoveCriteria(index)}
          viewUsers={criterion.count !== undefined}
        />
      ))}
    </Flex>
  )
}
