import { FormProvider, useForm } from "react-hook-form"
import {
  Button,
  Card,
  Toggle,
  Caption,
  User as UserInfo,
  Flex,
} from "playbook-ui"

import { AudienceContext, AudienceResource } from "../types"

import Header from "./Header"
import ScimResourceTypeahead from "./ScimResourceTypeahead"
import CriteriaListFields from "./CriteriaListFields"
import { ScimResourceType } from "../useScimResources"
import get from "lodash/get"
import { values } from "lodash"

export interface ResourceGroupInputs {
  [resourceType: string]: AudienceResource[]
}

export type AudienceContextInput = {
  resources: AudienceResource[]
  criteria: ResourceGroupInputs[]
  match_all: boolean
}

type AudienceFormProps = {
  userResource: ScimResourceType
  groupResources: ScimResourceType[]
  allowIndividuals: boolean
  context: AudienceContext
  loading?: boolean
  onSave: (updatedContext: AudienceContext) => void
  saving?: boolean
}

function denormalizeContext(context: AudienceContext): AudienceContextInput {
  return {
    match_all: context.match_all,
    resources: context.resources,
    criteria: context.criteria.map((criteria) =>
      criteria.resources.reduce(
        (current, resource) => ({
          ...current,
          [resource.resource_type]: [
            resource,
            ...get(current, resource.resource_type, []),
          ],
        }),
        {},
      ),
    ),
  }
}

function normalizeContext(input: AudienceContextInput): AudienceContext {
  return {
    match_all: input.match_all,
    resources: input.resources,
    criteria: input.criteria.map((criteria) => ({
      resources: values(criteria).flat(),
    })),
  }
}

const AudienceForm = ({
  userResource,
  groupResources,
  allowIndividuals = true,
  context,
  onSave,
  saving,
}: AudienceFormProps) => {
  const form = useForm<AudienceContextInput>({
    defaultValues: denormalizeContext(context),
  })
  function handleSave(value: AudienceContextInput) {
    onSave(normalizeContext(value))
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
            <CriteriaListFields resources={groupResources} name="criteria" />

            {allowIndividuals && userResource && (
              <ScimResourceTypeahead
                label="Other Members"
                name="resources"
                resource={userResource}
                valueComponent={(user: AudienceResource) => (
                  <UserInfo
                    avatar
                    avatarUrl={user.image_url}
                    name={user.display}
                  />
                )}
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
