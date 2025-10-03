import { Button, Icon, PbReactPopover, List, ListItem } from "playbook-ui"
import { MembersModal } from "./MembersModal"
import { GroupCriterion } from "../types"
import { CriteriaDescription } from "./CriteriaDescription"
import { useState } from "react"

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
  const [showMembers, setShowMembers] = useState(false)

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
      togglePopover(false)
    }
  }

  return (
    <>
      <PbReactPopover
        closeOnClick="outside"
        padding="xs"
        placement="bottom"
        reference={actionPopoverTrigger}
        shouldClosePopover={(close: boolean) => togglePopover(!close)}
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
              <Button
                variant="link"
                size="xs"
                padding="xs"
                onClick={handleAndClose(() => setShowMembers(true))}
                text="View Members"
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
      <MembersModal
        title={<CriteriaDescription groups={criterion.groups} />}
        total={criterion.count}
        criterion={criterion}
        showMembers={showMembers}
        setShowMembers={setShowMembers}
      />
    </>
  )
}
