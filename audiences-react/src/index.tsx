import { AudienceForm } from "./AudienceForm"
import Audiences, { useAudiences } from "./audiences"

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
  allowIndividuals?: boolean
}
export function AudienceEditor({
  uri,
  context,
  allowIndividuals = true,
}: AudienceEditorProps) {
  const audiencesUri = context ? uri : audiencesRoot(uri)
  const contextKey = context ? context : audiencesContext(uri)
  const audiences = useAudiences(audiencesUri, contextKey)

  return (
    <Audiences.Provider value={audiences}>
      <AudienceForm
        userResource={UserResourceId}
        groupResources={AllowedGroupIds}
        allowIndividuals={allowIndividuals}
      />
    </Audiences.Provider>
  )
}
