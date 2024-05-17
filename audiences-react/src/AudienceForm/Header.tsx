import { Flex, FlexItem, Caption, Toggle } from "playbook-ui"

import { useFormContext } from "react-hook-form"
import { MembersModalButton } from "./MembersModal"

type HeaderProps = {
  total: number
}
export function Header({ total }: HeaderProps) {
  const { register, formState } = useFormContext()

  return (
    <Flex orientation="row" spacing="between" wrap>
      <FlexItem>
        <Caption text={`Members ${formState.isDirty ? '' : total}`} />

        {formState.isDirty ? (
          <Caption
            size="xs"
            marginTop="sm"
            text="Audience members will update when the page is saved"
          />
        ) : (
          <MembersModalButton
            text="View All"
            title="All Members"
            padding="none"
            total={total}
          />
        )}
      </FlexItem>
      <FlexItem>
        <Flex justify="right" orientation="row">
          <Flex align="center">
            <Toggle>
              <input {...register("match_all")} type="checkbox" />
            </Toggle>
            <Caption marginLeft="xs" size="xs" text="All Employees" />
          </Flex>
        </Flex>
      </FlexItem>
    </Flex>
  )
}
