import { FormProvider, useForm } from "react-hook-form"
import { Card, Flex, Icon } from "playbook-ui"

import { AudienceContext } from "../types"

import { useAudienceContext } from "../audiences"
import { toSentence } from "./toSentence"

import { ScimResourceTypeahead } from "./ScimResourceTypeahead"
import { CriteriaList } from "./CriteriaList"
import { AllToggle } from "./AllToggle"
import { CriteriaForm } from "./CriteriaForm"
import { useCriteriaEditForm } from "./useCriteriaEditForm"

type AudienceFormProps = {
  userResource: string
  groupResources: string[]
  allowIndividuals: boolean
}

export const AudienceForm = ({
  userResource,
  groupResources,
  allowIndividuals = true,
}: AudienceFormProps) => {
  const { context, update } = useAudienceContext()
  const form = useForm<AudienceContext>({ values: context, mode: "onChange" })
  const { currentEditing, addNewCriteria, editCriteria, removeCriteria, closeCriteria } = useCriteriaEditForm({ form, groupResources })

  if (!context) {
    return (
      <Card>
        <Flex justify="center">
          <Icon fontStyle="fas" icon="spinner" spin />
        </Flex>
      </Card>
    )
  }

  return (
    <FormProvider {...form}>
      <form onSubmit={form.handleSubmit(update)} onReset={() => form.reset()}>
        {currentEditing === undefined ? (
          <AllToggle total={context.count} name="match_all">
            {allowIndividuals && (
              <ScimResourceTypeahead
                label="Add Individuals"
                name="extra_users"
                resourceId={userResource} />
            )}

            <CriteriaList
              addCriteriaLabel={`Add Members by ${toSentence(groupResources)}`}
              onAddCriteria={addNewCriteria}
              onRemoveCriteria={removeCriteria}
              onEditCriteria={editCriteria}
            />
          </AllToggle>
        ) : (
          <CriteriaForm
            current={`criteria.${currentEditing}`}
            onClose={closeCriteria}
          />
        )}
      </form>
    </FormProvider>
  )
}
