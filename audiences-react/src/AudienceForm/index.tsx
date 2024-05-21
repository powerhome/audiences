import { FormProvider, useForm } from "react-hook-form"
import { Button, Card, Flex, Icon } from "playbook-ui"

import { Header } from "./Header"
import { ScimResourceTypeahead } from "./ScimResourceTypeahead"
import { CriteriaListFields } from "./CriteriaListFields"
import { AudienceContext } from "../types"
import { useAudienceContext } from "../audiences"

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
  const form = useForm<AudienceContext>({ values: context })

  const all = form.watch("match_all")

  if (!context) {
    return (
      <Flex justify="center">
        <Icon fontStyle="fas" icon="spinner" spin />
      </Flex>
    )
  }

  return (
    <FormProvider {...form}>
      <Card margin="xs" padding="xs">
        <Card.Header headerColor={all ? "none" : "white"}>
          <Header total={context.count} />
        </Card.Header>

        {all || (
          <Card.Body>
            {allowIndividuals && userResource && (
              <ScimResourceTypeahead
                label="Add Individuals"
                name="extra_users"
                resourceId={userResource}
              />
            )}

            <CriteriaListFields
              groupResources={groupResources}
              name="criteria"
            />
          </Card.Body>
        )}

        <Card.Body>
          <div className="mt-5 pt-5">
            <Button
              disabled={!form.formState.isDirty || !form.formState.isValid || form.formState.isSubmitting}
              loading={form.formState.isSubmitting}
              onClick={form.handleSubmit(update)}
              text="Save"
            />
            {form.formState.isDirty && (
              <Button
                marginLeft="sm"
                onClick={() => form.reset()}
                text="Cancel"
                variant="link"
              />
            )}
          </div>
        </Card.Body>
      </Card>
    </FormProvider>
  )
}
