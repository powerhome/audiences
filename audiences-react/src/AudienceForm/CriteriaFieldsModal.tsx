import { useMemo } from "react"
import isEmpty from "lodash/isEmpty"
import map from "lodash/map"
import { Button, Dialog } from "playbook-ui"
import { useFormContext } from "react-hook-form"

import { CriteriaDescription } from "./CriteriaDescription"
import { ScimResourceTypeahead } from "./ScimResourceTypeahead"

export type CriteriaFieldsModalProps = {
  groupResources: string[]
  current: string
  onSave: () => void
  onCancel: (clear: boolean) => void
}
export function CriteriaFieldsModal({
  current,
  groupResources,
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
        <CriteriaDescription groups={value.groups} />
      </Dialog.Header>
      <Dialog.Body>
        {map(groupResources, (resourceId) => (
          <ScimResourceTypeahead
            resourceId={resourceId}
            key={`${current}.${resourceId}`}
            label={resourceId}
            name={`${current}.groups.${resourceId}`}
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
