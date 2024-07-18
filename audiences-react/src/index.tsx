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
  return (
    <Scim.Provider value={scimUri}>
      <AudienceForm
        uri={uri}
        userResource={UserResourceId}
        groupResources={AllowedGroupIds}
        allowIndividuals={allowIndividuals}
      />
    </Scim.Provider>
  )
}
