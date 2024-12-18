import { useState } from "react"
import { FixedConfirmationToast, Button, FlexItem } from "playbook-ui"
import { isEmpty } from "lodash/fp"

import { ScimObject } from "../types"
import { toSentence } from "./toSentence"

import { ScimResourceTypeahead } from "./ScimResourceTypeahead"
import { CriteriaList } from "./CriteriaList"
import { CriteriaForm } from "./CriteriaForm"
import { ActionBar } from "./ActionBar"
import { MatchAllToggleCard } from "./MatchAllToggleHeader"
import { useAudiencesContext } from "../audiences"

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
  const [ editing, setEditing ] = useState<number>()
  const { error, value: context, change} = useAudiencesContext()

  if (isEmpty(context)) {
    return null
  }

  if (editing !== undefined) {
    return (
      <CriteriaForm
        resources={groupResources}
        criterion={editing}
        onExit={() => setEditing(undefined)}
      />
    )
  }

  return (
    <MatchAllToggleCard>
      {error && (
        <FixedConfirmationToast status="error" text={error} margin="sm" />
      )}
      {!context.match_all && (
        <>
          {allowIndividuals && <ScimResourceTypeahead
            label="Add Individuals"
            value={context.extra_users || []}
            onChange={(users: ScimObject[]) => change("extra_users", users)}
            resourceId={userResource}
          />}
          <CriteriaList onEditCriteria={setEditing} />
          <FlexItem alignSelf="center">
            <Button
              fixedWidth
              marginTop="md"
              onClick={() => setEditing(context.criteria.length)}
              text={`Add Members by ${toSentence(groupResources)}`}
              variant="link"
            />
          </FlexItem>
        </>
      )}

      <ActionBar />
    </MatchAllToggleCard>
  )
}
