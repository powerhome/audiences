import { flatten, isEmpty, keys, values } from "lodash"
import { Button, Card, Flex, IconValue } from "playbook-ui"
import { useFormContext } from "react-hook-form"

import { CriteriaDescription } from "./CriteriaDescription"
import { ScimResourceTypeahead } from "./ScimResourceTypeahead"
import { useMemo } from "react"

export type CriteriaFormProps = {
  current: string
  onClose: () => void
}
export function CriteriaForm({ current, onClose }: CriteriaFormProps) {
  const { setValue, watch } = useFormContext()
  const value = watch(`${current}.groups`)
  const initialValue = useMemo(() => ({ ...value }), [current])

  const emptyCriteria = isEmpty(flatten(values(value)))

  const handleCancel = () => {
    setValue(`${current}.groups`, initialValue)
    onClose()
  }

  return (
    <Card>
      <Card.Header headerColor="white">
        <Button onClick={handleCancel} variant="link" padding="none">
          <IconValue
            fixedWidth
            icon="chevron-left"
            align="left"
            size="1x"
            text="Filter Members"
          />
        </Button>
      </Card.Header>

      <Card.Body>
        {keys(value).map((resourceId) => (
          <ScimResourceTypeahead
            resourceId={resourceId}
            key={`${current}.${resourceId}`}
            label={resourceId}
            name={`${current}.groups.${resourceId}`}
          />
        ))}

        {emptyCriteria || <CriteriaDescription groups={value} />}

        <Flex justify="between" marginTop="md">
          <Button onClick={onClose} text="Save" disabled={emptyCriteria} />
          <Button onClick={handleCancel} text="Cancel" variant="link" />
        </Flex>
      </Card.Body>
    </Card>
  )
}
