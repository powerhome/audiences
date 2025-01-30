import { Flex, Button } from "playbook-ui"
import { useAudiencesContext } from "../audiences"
import { useState } from "react"

export function ActionBar() {
  const { save, isDirty, reset } = useAudiencesContext()
  const [saving, setSaving] = useState(false)

  async function handleSave() {
    setSaving(true)
    await save()
    setSaving(false)
  }

  return (
    <Flex justify="between" marginTop="md">
      <Button
        disabled={!isDirty()}
        text="Save"
        htmlType="submit"
        saving={saving}
        onClick={handleSave}
      />

      {isDirty() && (
        <Button
          marginLeft="sm"
          text="Cancel"
          variant="link"
          htmlType="reset"
          onClick={() => reset()}
        />
      )}
    </Flex>
  )
}
