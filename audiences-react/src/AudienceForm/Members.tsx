import { Caption, Button } from "playbook-ui"
import { useFormContext } from "react-hook-form"

type MembersProps = {
  count: number
  onShowAllMembers: () => void
}

export function Members({ count, onShowAllMembers }: MembersProps) {
  const { formState } = useFormContext()

  return (
    <>
      <Caption tag="span" text="Audience Total" />
      {formState.isDirty ? (
        <Caption
          size="xs"
          text="Audience total will update when the page is saved"
        />
      ) : (
        <Caption marginLeft="xs" size="xs" tag="span" text={count} />
      )}

      {count > 0 && (
        <div>
          <Button
            onClick={onShowAllMembers}
            padding="none"
            text="View All Members"
            variant="link"
          />
        </div>
      )}
    </>
  )
}
