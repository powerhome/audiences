import { AudienceForm } from "./AudienceForm"
import Audiences, { useAudience } from "./audiences"
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
  const context = useAudience(uri)

  return (
    <Scim.Provider value={scimUri}>
      <Audiences.Provider value={context}>
        <AudienceForm
          userResource={UserResourceId}
          groupResources={AllowedGroupIds}
          allowIndividuals={allowIndividuals}
        />
      </Audiences.Provider>
    </Scim.Provider>
  )
}
