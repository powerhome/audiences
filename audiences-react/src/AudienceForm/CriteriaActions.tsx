import { Button, Icon, PbReactPopover, List, ListItem } from "playbook-ui"
import { MembersModalButton } from "./MembersModalButton"
import { GroupCriterion } from "../types"
import { CriteriaDescription } from "./CriteriaDescription"

type CriteriaActionsProps = {
  criterion: GroupCriterion
  onRequestEdit: () => void
  onRequestRemove: () => void
  viewUsers: boolean
  showPopover: boolean
  setShowPopover: (show: boolean) => void
}
export function CriteriaActions({
  viewUsers,
  criterion,
  onRequestRemove,
  onRequestEdit,
  showPopover,
  setShowPopover,
}: CriteriaActionsProps) {
  const switchPopover = () => setShowPopover(!showPopover)

  const actionPopoverTrigger = (
    <div className="pb_circle_icon_button_kit">
      <Button className="" onClick={switchPopover} variant="link">
        <Icon fixedWidth icon="ellipsis" />
      </Button>
    </div>
  )

  const handleAndClose = (handler: () => void) => {
    return () => {
      handler()
      setShowPopover(false)
    }
  }

  return (
    <PbReactPopover
      closeOnClick="outside"
      padding="xs"
      placement="bottom"
      reference={actionPopoverTrigger}
      shouldClosePopover={(close: boolean) => {
        setShowPopover(!close)
      }}
      show={showPopover}
      zIndex={10}
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
