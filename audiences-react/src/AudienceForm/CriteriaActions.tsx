import { Button, Icon, PbReactPopover, List, ListItem } from "playbook-ui"
import { useState } from "react"
import { MembersModalButton } from "./MembersModalButton"
import { GroupCriterion } from "../types"
import { CriteriaDescription } from "./CriteriaDescription"

type CriteriaActionsProps = {
  criterion: GroupCriterion
  onRequestEdit: () => void
  onRequestRemove: () => void
  viewUsers: boolean
}
export function CriteriaActions({
  viewUsers,
  criterion,
  onRequestRemove,
  onRequestEdit,
}: CriteriaActionsProps) {
  const [showPopover, togglePopover] = useState(false)
  const switchPopover = () => togglePopover(!showPopover)

  const actionPopoverTrigger = (
    <div className="pb_circle_icon_button_kit">
      <Button className="" onClick={switchPopover} variant="link">
        <Icon
          fixedWidth
          fontStyle="fas"
          icon="ellipsis-vertical"
          rotation={90}
        />
      </Button>
    </div>
  )

  const handleAndClose = (handler: () => void) => {
    return () => {
      handler()
      togglePopover(false)
    }
  }

  return (
    <PbReactPopover
      closeOnClick="outside"
      padding="xs"
      placement="bottom"
      reference={actionPopoverTrigger}
      shouldClosePopover={(close: boolean) => togglePopover(!close)}
      show={showPopover}
    >
      <List>
        <ListItem padding="none">
          <Button
            variant="link"
            size="xs"
            padding="xs"
            onClick={handleAndClose(onRequestEdit)}
            text="Edit Filter"
          />
        </ListItem>
        <ListItem padding="none">
          {viewUsers && (
            <MembersModalButton
              padding="xs"
              text="View Members"
              title={<CriteriaDescription groups={criterion.groups} />}
              total={criterion.count}
              criterion={criterion}
            />
          )}
        </ListItem>
        <ListItem padding="none">
          <Button
            variant="link"
            size="xs"
            padding="xs"
            onClick={handleAndClose(onRequestRemove)}
            text="Delete Filter"
          />
        </ListItem>
      </List>
    </PbReactPopover>
  )
}
