import { AudienceForm } from "./AudienceForm"
import Scim from "./scim"
import { useAudiences } from "./audiences"

const UserResourceId = "Users"
const AllowedGroupIds = ["Territories", "Departments", "Titles"]

type AudienceEditorProps = {
  uri: string
  scimUri: string
  allowIndividuals?: boolean
  fetchOptions?: Parameters<typeof useAudiences>[1]
}
export function AudienceEditor({
  uri,
  scimUri,
  allowIndividuals = true,
  fetchOptions = {},
}: AudienceEditorProps) {
  return (
    <Scim.Provider value={scimUri}>
      <AudienceForm
        uri={uri}
        userResource={UserResourceId}
        groupResources={AllowedGroupIds}
        allowIndividuals={allowIndividuals}
        fetchOptions={fetchOptions}
      />
    </Scim.Provider>
  )
}
