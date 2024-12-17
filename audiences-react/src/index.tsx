import { AudienceForm } from "./AudienceForm"
import Audiences, { useAudiences } from "./audiences"
import Scim from "./scim"

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
  const audiences = useAudiences(uri, fetchOptions)

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
