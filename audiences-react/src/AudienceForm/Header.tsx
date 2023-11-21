import { Flex, FlexItem, Caption } from "playbook-ui"

import { Members } from "./Members"
import type { AudienceContext } from "../types"

type HeaderProps = React.PropsWithChildren & {
  context: AudienceContext
}
export function Header({ context, children }: HeaderProps) {
  return (
    <Flex orientation="row" spacing="between" wrap>
      <FlexItem>
        <Members count={context.count} onShowAllMembers={() => undefined} />
      </FlexItem>
      <FlexItem>
        <Flex justify="right" orientation="row">
          {children}
        </Flex>
      </FlexItem>
    </Flex>
  )
}
