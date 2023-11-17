import { useState } from "react"
import { Button, Flex, FlexItem } from "playbook-ui"
import { useFieldArray, useFormContext } from "react-hook-form"
import isEmpty from "lodash/isEmpty"
import every from "lodash/every"
import omitBy from "lodash/omitBy"

import { CriteriaActions } from "./CriteriaActions"
import { CriteriaCard } from "./CriteriaCard"
import { CriteriaFieldsModal } from "./CriteriaFieldsModal"
import { GroupCriteria } from "../types"

type GroupCriteriaField = GroupCriteria & {
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
  const { fields, remove, append } = useFieldArray({
    name,
    rules: {
      validate: (criteria) => {
        return every(criteria, (c: GroupCriteria) => {
          return !isEmpty(omitBy(c, isEmpty))
        })
      },
    },
  })
  const [currentEditing, editCriteria] = useState<number | undefined>()

  const closeEditor = () => editCriteria(undefined)
  const watchFieldArray = form.watch(name) || []
  const controlledFields = fields.map((field, index) => {
    return {
      ...field,
      ...watchFieldArray[index],
    }
  })

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
    if (!valid) {
      remove(currentEditing)
    }
    closeEditor()
  }

  return (
    <Flex orientation="column" justify="center" align="stretch">
      <FlexItem>
        {(controlledFields as GroupCriteriaField[]).map(
          (criteria, index: number) => (
            <CriteriaCard criteria={criteria} key={criteria.id}>
              <CriteriaActions
                onRequestRemove={() => handleRemoveCriteria(index)}
                onRequestEdit={() => editCriteria(index)}
                onRequestViewMembers={() => {}}
              />
            </CriteriaCard>
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
