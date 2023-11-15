import { Flex, FlexItem, Caption } from "playbook-ui"
import { useFormContext } from "react-hook-form"

import { Members } from "./Members"
import type { AudienceContext } from "../types"

type HeaderProps = React.PropsWithChildren & {
  context: AudienceContext
}
export function Header({ context, children }: HeaderProps) {
  const { formState } = useFormContext()

  return (
    <Flex orientation="row" spacing="between" wrap>
      <FlexItem>
        {formState.isDirty ? (
          <>
            <Caption tag="span" text="Audience Total" />
            <Caption
              size="xs"
              text="Audience total will update when the page is saved"
            />
          </>
        ) : (
          <Members
            count={context.count}
            showAll
            onShowAllMembers={() => undefined}
          />
        )}
      </FlexItem>
      <FlexItem>
        <Flex justify="right" orientation="row">
          {children}
        </Flex>
      </FlexItem>
    </Flex>
  )
}
