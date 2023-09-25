import { Flex, Icon } from "playbook-ui"

import AudienceForm from "./AudienceForm"
import useAudience from "./useAudience"
import { useScimResources } from "./useScimResources"
import { filter, find } from "lodash"

const UserResourceId = "User"
const AllowedGroupIds = ["Territory", "Department", "Title"]

type AudienceEditorProps = {
  uri: string
  scimUri: string
  allowIndividuals?: boolean
}
export default function AudienceEditor({
  uri,
  scimUri,
  allowIndividuals = true,
}: AudienceEditorProps) {
  const [context, updateContext] = useAudience(uri)
  const { resources } = useScimResources(scimUri)

  const userResource = find(resources, { id: UserResourceId })
  const groupResources = filter(resources, (resource) =>
    AllowedGroupIds.includes(resource.id),
  )

  if (!context || !resources) {
    return (
      <Flex justify="center">
        <Icon fontStyle="fas" icon="spinner" spin />
      </Flex>
    )
  }

  return (
    <AudienceForm
      userResource={userResource!}
      groupResources={groupResources}
      context={context}
      allowIndividuals={allowIndividuals}
      onSave={updateContext}
    />
  )
}
