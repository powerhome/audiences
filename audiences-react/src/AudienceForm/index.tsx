import { useState } from "react"
import { Button, Flex } from "playbook-ui"

import { GroupCriterion, ScimObject } from "../types"
import { toSentence } from "./toSentence"

import { ScimResourceTypeahead } from "./ScimResourceTypeahead"
import { CriteriaList } from "./CriteriaList"
import { CriteriaForm } from "./CriteriaForm"
import { useAudiences } from "../audiences"
import { MatchAllToggleCard } from "./MatchAllToggleHeader"

type AudienceFormProps = {
  uri: string
  userResource: string
  groupResources: string[]
  allowIndividuals: boolean
}

export const AudienceForm = ({
  uri,
  userResource,
  groupResources,
  allowIndividuals = true,
}: AudienceFormProps) => {
  const [editing, setEditing] = useState<number>()

  const {
    saving,
    fetchUsers,
    save,
    value: context,
    isDirty,
    change,
    reset,
    removeCriteria,
    updateCriteria,
  } = useAudiences(uri)

  const handleRemoveCriteria = (index: number) => {
    if (confirm("Remove criteria?")) {
      removeCriteria(index)
    }
  }

  const handleSaveCriteria = (criterion: GroupCriterion) => {
    updateCriteria(editing!, criterion)
    setEditing(undefined)
  }

  const handleCreateCriteria = () => {
    setEditing(context.criteria.length)
  }

  if (!context) {
    return null
  }

  if (editing !== undefined) {
    return (
      <CriteriaForm
        resources={groupResources}
        criterion={context.criteria[editing]}
        onSave={handleSaveCriteria}
        onCancel={() => setEditing(undefined)}
      />
    )
  }

  return (
    <MatchAllToggleCard
      count={context.count}
      enabled={context.match_all}
      fetchUsers={fetchUsers}
      isDirty={isDirty()}
      onToggle={(all: boolean) => change("match_all", all)}
    >
      {allowIndividuals && !context.match_all && (
        <ScimResourceTypeahead
          label="Add Individuals"
          value={context.extra_users || []}
          onChange={(users: ScimObject[]) => change("extra_users", users)}
          resourceId={userResource}
        />
      )}
      {!context.match_all && (
        <CriteriaList
          addCriteriaLabel={`Add Members by ${toSentence(groupResources)}`}
          context={context}
          fetchUsers={fetchUsers}
          onAddCriteria={handleCreateCriteria}
          onEditCriteria={setEditing}
          onRemoveCriteria={handleRemoveCriteria}
        />
      )}

      <Flex justify="between" marginTop="md">
        <Button
          disabled={!isDirty}
          text="Save"
          htmlType="submit"
          loading={saving}
          onClick={() => save()}
        />

        {isDirty() && (
          <Button
            marginLeft="sm"
            text="Cancel"
            variant="link"
            htmlType="reset"
            onClick={() => reset()}
          />
        )}
      </Flex>
    </MatchAllToggleCard>
  )
}
