import { Flex, FlexItem, Caption, Toggle } from "playbook-ui"

import { Members } from "./Members"
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
        <Members total={total} />

        {formState.isDirty || (
          <MembersModalButton
            text="View All Members"
            title="All users"
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
