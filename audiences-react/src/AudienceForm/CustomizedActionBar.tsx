import { Flex, Button } from "playbook-ui"
import { useAudiencesContext } from "../audiences"
import { useState } from "react"

export function CustomizedActionBar({
  isMobile = false,
  isSkipButton = false,
  onSkip,
}: {
  isMobile?: boolean
  isSkipButton?: boolean
  onSkip: () => void
}) {
  const { save, isDirty, reset } = useAudiencesContext()
  const [saving, setSaving] = useState(false)

  async function handleSave() {
    setSaving(true)
    await save()
    setSaving(false)
    if (onSkip) onSkip()
  }

  return isSkipButton ? (
    <Flex
      orientation={isMobile ? "column" : "row"}
      justify={isMobile ? "center" : "between"}
      align="center"
      marginTop="md"
      paddingX={isMobile ? "xs" : "md"}
      paddingBottom={isMobile ? "" : "md"}
    >
      <Button
        fullWidth={isMobile}
        disabled={!isDirty()}
        text="Save"
        htmlType="submit"
        saving={saving}
        onClick={handleSave}
      />
      <Button
        fullWidth={isMobile}
        marginTop="xs"
        text="Skip for now"
        variant="secondary"
        htmlType="reset"
        onClick={() => {
          if (isDirty()) reset()
          if (onSkip) onSkip()
        }}
      />
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
      <Button
        marginLeft="sm"
        text="Cancel"
        variant="link"
        htmlType="reset"
        onClick={() => {
          if (isDirty()) reset()
          if (onSkip) onSkip()
        }}
      />
    </Flex>
  )
}
