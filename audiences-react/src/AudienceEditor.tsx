import { Flex, Icon } from "playbook-ui"

import { useAudience } from "./useAudience"
import { AudienceForm } from "./AudienceForm"
import Scim from "./scim"

const UserResourceId = "Users"
const AllowedGroupIds = ["Territories", "Departments", "Titles"]

type AudienceEditorProps = {
  uri: string
  scimUri: string
  allowIndividuals?: boolean
}
export function AudienceEditor({
  uri,
  scimUri,
  allowIndividuals = true,
}: AudienceEditorProps) {
  const { context, update } = useAudience(uri)

  if (context) {
    return (
      <Scim.Provider value={scimUri}>
        <AudienceForm
          userResource={UserResourceId}
          groupResources={AllowedGroupIds}
          context={context}
          allowIndividuals={allowIndividuals}
          onSave={update}
        />
      </Scim.Provider>
    )
  } else {
    return (
      <Flex justify="center">
        <Icon fontStyle="fas" icon="spinner" spin />
      </Flex>
    )
  }
}
