import { Flex, FlexItem, Caption, Toggle } from "playbook-ui"

import { Members } from "./Members"
import { useFormContext } from "react-hook-form"
import { MembersModalButton } from "./MembersModal"

type HeaderProps = {
  count: number
}
export function Header({ count }: HeaderProps) {
  const { register, formState } = useFormContext()

  return (
    <Flex orientation="row" spacing="between" wrap>
      <FlexItem>
        <Members count={count} />

        {formState.isDirty || (
          <MembersModalButton
            label="View All Members"
            title="All users"
            count={count}
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
