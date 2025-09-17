import { useState } from "react"
import {
  FixedConfirmationToast,
  Button,
  Flex,
  Card,
  FlexItem,
} from "playbook-ui"
import { isEmpty } from "lodash/fp"

import { ScimObject } from "../types"
import { toSentence } from "./toSentence"

import { ScimResourceTypeahead } from "./ScimResourceTypeahead"
import { MobileTypeahead } from "./MobileTypeahead"
import { CriteriaList } from "./CriteriaList"
import { CriteriaForm } from "./CriteriaForm"
import { ActionBar } from "./ActionBar"
import { MatchAllToggleHeader } from "./MatchAllToggleHeader"
import { useAudiencesContext } from "../audiences"

type AudienceFormProps = {
  userResource: string
  groupResources: string[]
  allowIndividuals: boolean
  allowMatchAll: boolean
  isMobile?: boolean
  onSkip?: () => void
}

export const AudienceForm = ({
  userResource,
  groupResources,
  allowIndividuals = true,
  allowMatchAll = true,
  isMobile,
  onSkip,
}: AudienceFormProps) => {
  const [editing, setEditing] = useState<number>()
  const { error, value: context, change } = useAudiencesContext()

  if (isEmpty(context)) {
    return null
  }

  if (editing !== undefined) {
    return (
      <CriteriaForm
        resources={groupResources}
        criterion={editing}
        isMobile={isMobile}
        onSkip={onSkip}
        onExit={() => setEditing(undefined)}
      />
    )
  }

  return (
    <Card margin="xs" padding="xs" borderNone={isMobile}>
      <Card.Header
        paddingX={isMobile && "xs"}
        headerColor={context.match_all ? "none" : "white"}
      >
        <MatchAllToggleHeader
          allowMatchAll={allowMatchAll}
          isMobile={isMobile}
        />
      </Card.Header>
      <Card.Body paddingX={isMobile && "xs"}>
        <Flex orientation="column" align="stretch">
          {error && (
            <FixedConfirmationToast status="error" text={error} margin="sm" />
          )}
          {!context.match_all && (
            <>{isMobile ? 
                            (allowIndividuals && (
                <MobileTypeahead
                  label="Add Individuals"
                  value={context.extra_users || []}
                  onChange={(users: ScimObject[]) =>
                    change("extra_users", users)
                  }
                  resourceId={userResource}
                  isMobile={isMobile}
                />
              ))
              :
              (allowIndividuals && (
                <ScimResourceTypeahead
                  label="Add Individuals"
                  value={context.extra_users || []}
                  onChange={(users: ScimObject[]) =>
                    change("extra_users", users)
                  }
                  resourceId={userResource}
                />
              ))
            }
              <CriteriaList onEditCriteria={setEditing} />
              <FlexItem alignSelf="center">
                <Button
                  fixedWidth
                  marginTop="md"
                  paddingX={isMobile && "xs"}
                  size={isMobile ? "sm" : "md"}
                  onClick={() => setEditing(context.criteria.length)}
                  text={`Add Members by ${toSentence(groupResources)}`}
                  variant="link"
                />
              </FlexItem>
            </>
          )}
        </Flex>
      </Card.Body>
      <ActionBar isMobile={isMobile} onSkip={onSkip} />
    </Card>
  )
}
