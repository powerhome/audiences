import { AudienceForm } from "./AudienceForm"
import Audiences, { useAudiences } from "./audiences"
import Scim from "./scim"

function audiencesRoot(uri: string): string {
  return uri.match(/.*(?=\/)/g)?.at(0)!
}

function audiencesContext(uri: string): string {
  return uri.match(/[^\/]+$/g)?.at(0)!
}

const UserResourceId = "Users"
const AllowedGroupIds = ["Territories", "Departments", "Titles"]

type AudienceEditorProps = {
  uri: string
  context?: string
  scimUri: string
  allowIndividuals?: boolean
  fetchOptions?: Parameters<typeof useAudiences>[2]
}
export function AudienceEditor({
  uri,
  context,
  scimUri,
  allowIndividuals = true,
  fetchOptions = {},
}: AudienceEditorProps) {
  const audiencesUri = context ? uri : audiencesRoot(uri)
  const contextKey = context ? context : audiencesContext(uri)
  const audiences = useAudiences(audiencesUri, contextKey, fetchOptions)

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
