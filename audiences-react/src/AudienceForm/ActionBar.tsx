import { Flex, Button } from "playbook-ui"
import { useAudiencesContext } from "../audiences"
import { useState } from "react"

export function ActionBar({
  isMobile = false,
  onSkip,
}: {
  isMobile?: boolean
  onSkip?: () => void
}) {
  const { save, isDirty, reset } = useAudiencesContext()
  const [saving, setSaving] = useState(false)

  async function handleSave() {
    setSaving(true)
    await save()
    setSaving(false)
  }

  return isMobile ? (
    <Flex orientation="column" align="center" marginTop="md" paddingX="xs">
      <Button
        fullWidth
        disabled={!isDirty()}
        text="Save"
        htmlType="submit"
        saving={saving}
        onClick={handleSave}
      />

      {isDirty() && (
        <Button
          fullWidth
          marginTop="xs"
          text="Skip for now"
          variant="secondary"
          htmlType="reset"
          onClick={() => {
            reset()
            if (onSkip) onSkip()
          }}
        />
      )}
    </Flex>
  ) : (
    <Flex justify="between" paddingX="md" paddingBottom="md">
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
