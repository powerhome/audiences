import { FormProvider, useForm } from "react-hook-form"
import { Button, Card, Toggle, Caption, Flex } from "playbook-ui"

import { Header } from "./Header"
import { ScimResourceTypeahead } from "./ScimResourceTypeahead"
import { CriteriaListFields } from "./CriteriaListFields"
import { AudienceContext } from "../types"

type AudienceFormProps = {
  userResource: string
  groupResources: string[]
  allowIndividuals: boolean
  context: AudienceContext
  loading?: boolean
  onSave: (updatedContext: AudienceContext) => void
  saving?: boolean
}

export const AudienceForm = ({
  userResource,
  groupResources,
  allowIndividuals = true,
  context,
  onSave,
  saving,
}: AudienceFormProps) => {
  const form = useForm<AudienceContext>({
    defaultValues: context,
  })

  const all = form.watch("match_all")

  return (
    <FormProvider {...form}>
      <Card margin="xs" padding="xs">
        <Card.Header headerColor="white">
          <Header context={context}>
            <Flex align="center">
              <Toggle>
                <input {...form.register("match_all")} type="checkbox" />
              </Toggle>
              <Caption marginLeft="xs" size="xs" text="All Employees" />
            </Flex>
          </Header>
        </Card.Header>

        {all || (
          <Card.Body>
            <CriteriaListFields
              groupResources={groupResources}
              name="criteria.groups"
            />

            {allowIndividuals && userResource && (
              <ScimResourceTypeahead
                label="Other Members"
                name="extra_users"
                resourceId={userResource}
              />
            )}
          </Card.Body>
        )}

        <Card.Body>
          <div className="mt-5 pt-5">
            <Button
              disabled={saving}
              onClick={form.handleSubmit(onSave)}
              loading={saving}
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
