import { AudienceForm } from "./AudienceForm"
import Audiences, { useAudiences } from "./audiences"
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
  const audiences = useAudiences(uri)

  return (
    <Audiences.Provider value={audiences}>
      <Scim.Provider value={scimUri}>
        <AudienceForm
          userResource={UserResourceId}
          groupResources={AllowedGroupIds}
          allowIndividuals={allowIndividuals}
        />
      </Scim.Provider>
    </Audiences.Provider>
  )
}
