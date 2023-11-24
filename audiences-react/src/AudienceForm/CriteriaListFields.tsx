import { useState } from "react"
import { Button, Flex, FlexItem } from "playbook-ui"
import { useFieldArray, useFormContext } from "react-hook-form"
import isEmpty from "lodash/isEmpty"
import every from "lodash/every"
import omitBy from "lodash/omitBy"

import { CriteriaCard } from "./CriteriaCard"
import { CriteriaFieldsModal } from "./CriteriaFieldsModal"
import { GroupCriterion } from "../types"

type GroupCriterionField = GroupCriterion & {
  id: string
}
type CriteriaListFieldsProps = {
  name: string
  groupResources: string[]
}
export function CriteriaListFields({
  name,
  groupResources,
}: CriteriaListFieldsProps) {
  const form = useFormContext()
  const [currentEditing, editCriteria] = useState<number | undefined>()
  const { fields, remove, append } = useFieldArray({
    name,
    rules: {
      validate: (criteria) => {
        return every(criteria, (c: GroupCriterion) => {
          return !isEmpty(omitBy(c.groups, isEmpty))
        })
      },
    },
  })

  const closeEditor = () => editCriteria(undefined)
  const watchFieldArray = form.watch(name) || []
  const controlledFields = fields.map((field, index) => {
    return {
      ...field,
      ...watchFieldArray[index],
    }
  })
  const isCriterionDirty = (index: number) =>
    form.getFieldState(`${name}.${index}`).isDirty

  const handleCreateCriteria = () => {
    append({})
    editCriteria(fields.length)
  }
  const handleRemoveCriteria = (index: number) => {
    if (confirm("Remove criteria?")) {
      remove(index)
    }
  }
  const validateAndClose = async () => {
    const valid = await form.trigger(name)
    closeEditor()
    if (!valid) {
      remove(currentEditing)
    }
  }

  return (
    <Flex orientation="column" justify="center" align="stretch">
      <FlexItem>
        {(controlledFields as GroupCriterionField[]).map(
          (criterion, index: number) => (
            <CriteriaCard
              criterion={criterion}
              key={`criterion-${criterion.id}`}
              viewUsers={!isCriterionDirty(index)}
              onRequestRemove={() => handleRemoveCriteria(index)}
              onRequestEdit={() => editCriteria(index)}
            />
          ),
        )}
      </FlexItem>

      <FlexItem grow alignSelf="center">
        <Button
          fixedWidth
          onClick={handleCreateCriteria}
          text="Add Audience Criteria"
          variant="link"
        />
      </FlexItem>

      {currentEditing !== undefined && (
        <CriteriaFieldsModal
          groupResources={groupResources}
          current={`${name}.${currentEditing}`}
          onCancel={validateAndClose}
          onSave={validateAndClose}
        />
      )}
    </Flex>
  )
}
