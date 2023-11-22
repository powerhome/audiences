import { Button, Icon, PbReactPopover, List, ListItem } from "playbook-ui"
import { useState } from "react"
import { MembersModalButton } from "./MembersModal"
import { GroupCriterion } from "../types"
import { CriteriaDescription } from "./CriteriaDescription"

type CriteriaActionsProps = {
  criterion: GroupCriterion
  onRequestRemove: () => void
  onRequestEdit: () => void
}
export function CriteriaActions({
  criterion,
  onRequestRemove,
  onRequestEdit,
}: CriteriaActionsProps) {
  const [showPopover, togglePopover] = useState(false)
  const switchPopover = () => togglePopover(!showPopover)

  const actionPopoverTrigger = (
    <div className="pb_circle_icon_button_kit">
      <Button className="" onClick={switchPopover} variant="link">
        <Icon fixedWidth fontStyle="fas" icon="ellipsis-vertical" />
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
            text="Edit"
          />
        </ListItem>
        <ListItem padding="none">
          <MembersModalButton
            padding="xs"
            text="Users"
            title={<CriteriaDescription groups={criterion.groups} />}
            count={criterion.count}
          />
        </ListItem>
        <ListItem padding="none">
          <Button
            variant="link"
            size="xs"
            padding="xs"
            onClick={handleAndClose(onRequestRemove)}
            text="Delete"
          />
        </ListItem>
      </List>
    </PbReactPopover>
  )
}
