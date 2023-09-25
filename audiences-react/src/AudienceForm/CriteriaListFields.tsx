import { useState } from "react"
import { Button, Flex, FlexItem } from "playbook-ui"
import { useFieldArray, useFormContext } from "react-hook-form"

import CriteriaActions from "./CriteriaActions"
import CriteriaCard from "./CriteriaCard"
import CriteriaFieldsModal from "./CriteriaFieldsModal"
import { AudienceContextInput, ResourceGroupInputs } from "."
import { ScimResourceType } from "../useScimResources"
import isEmpty from "lodash/isEmpty"
import { every, omitBy } from "lodash"

type AudienceCriteriaField = AudienceContextInput["criteria"][0] & {
  id: string
}
export type CriteriaListProps = {
  name: string
  resources: ScimResourceType[]
}
export default function CriteriaListFields({
  name,
  resources,
}: CriteriaListProps) {
  const form = useFormContext()
  const { fields, remove, append } = useFieldArray({
    name,
    rules: {
      validate: (criteria) => {
        return every(criteria, (c: ResourceGroupInputs) => {
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
        {(controlledFields as AudienceCriteriaField[]).map(
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
          resourceTypes={resources}
          current={`${name}.${currentEditing}`}
          onCancel={validateAndClose}
          onSave={validateAndClose}
        />
      )}
    </Flex>
  )
}
