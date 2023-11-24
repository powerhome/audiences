import { Caption } from "playbook-ui"
import { useFormContext } from "react-hook-form"

type MembersProps = {
  count: number
}

export function Members({ count }: MembersProps) {
  const { formState } = useFormContext()

  return (
    <div>
      <Caption tag="span" text="Audience Total" />
      {formState.isDirty ? (
        <Caption
          size="xs"
          text="Audience total will update when the page is saved"
        />
      ) : (
        <Caption marginLeft="xs" size="xs" tag="span" text={count} />
      )}
    </div>
  )
}
