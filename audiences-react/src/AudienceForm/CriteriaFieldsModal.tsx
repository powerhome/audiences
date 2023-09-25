import { useMemo } from "react"
import isEmpty from "lodash/isEmpty"
import map from "lodash/map"
import { Button, Dialog } from "playbook-ui"
import { useFormContext } from "react-hook-form"

import { CriteriaDescription } from "./CriteriaDescription"
import { ScimResourceTypeahead } from "./ScimResourceTypeahead"
import { ScimResourceType } from "../useScimResources"

export type CriteriaFieldsModalProps = {
  resourceTypes: ScimResourceType[]
  current: string
  onSave: () => void
  onCancel: (clear: boolean) => void
}
export function CriteriaFieldsModal({
  current,
  resourceTypes,
  onSave,
  onCancel,
}: CriteriaFieldsModalProps) {
  const { watch, setValue } = useFormContext()
  const value = watch(current)
  const initialValue = useMemo(() => ({ ...value }), [current])
  const handleCancel = () => {
    setValue(current, initialValue)
    onCancel(isEmpty(initialValue))
  }

  return (
    <Dialog onClose={handleCancel} opened>
      <Dialog.Header>
        <CriteriaDescription criteria={value} />
      </Dialog.Header>
      <Dialog.Body>
        {map(resourceTypes, (resource) => (
          <ScimResourceTypeahead
            resource={resource}
            key={`${current}.${resource.id}`}
            label={resource.name}
            name={`${current}.${resource.id}` as const}
          />
        ))}
      </Dialog.Body>
      <Dialog.Footer>
        <Button onClick={onSave} text="Save" disabled={isEmpty(value)} />
        <Button onClick={handleCancel} text="Cancel" variant="link" />
      </Dialog.Footer>
    </Dialog>
  )
}
