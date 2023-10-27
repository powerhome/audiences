import { FormProvider, useForm } from "react-hook-form"
import { Button, Card, Toggle, Caption, User, Flex } from "playbook-ui"

import { AudienceContext } from "../types"

import Header from "./Header"
import ScimResourceTypeahead from "./ScimResourceTypeahead"
import CriteriaListFields from "./CriteriaListFields"
import { ScimResourceType } from "../useScimResources"

type AudienceFormProps = {
  userResource: ScimResourceType
  groupResources: ScimResourceType[]
  allowIndividuals: boolean
  context: AudienceContext
  loading?: boolean
  onSave: (updatedContext: AudienceContext) => void
  saving?: boolean
}

const AudienceForm = ({
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
  function handleSave(value: AudienceContext) {
    onSave(value)
  }

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
              resources={groupResources}
              name="criteria.groups"
            />

            {allowIndividuals && userResource && (
              <ScimResourceTypeahead
                label="Other Members"
                name="criteria.users"
                resource={userResource}
                // valueComponent={(user: any) => (
                //   <UserInfo
                //     avatar
                //     avatarUrl={user?.image_url}
                //     name={user?.display}
                //   />
                // )}
              />
            )}
          </Card.Body>
        )}

        <Card.Body>
          <div className="mt-5 pt-5">
            <Button
              disabled={saving}
              onClick={form.handleSubmit(handleSave)}
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
export default AudienceForm
