import React, { useEffect, useState } from "react"
import { get } from "lodash"
import {
  Body,
  Button,
  Caption,
  List,
  ListItem,
  Dialog,
  Flex,
  TextInput,
  User,
} from "playbook-ui"

import type { GroupCriterion, ScimObject } from "../types"
import { useAudienceContext } from "../audiences"

type MembersModalButtonProps = any & {
  title: React.ReactNode
  criterion: GroupCriterion
  count: number
}

export function MembersModalButton({
  title,
  count,
  criterion,
  ...buttonOptions
}: MembersModalButtonProps) {
  const [loading, setLoading] = useState<boolean>()
  const [users, setUsers] = useState<ScimObject[]>([])
  const [search, setSearch] = useState("")
  const { fetchUsers } = useAudienceContext()
  const [showMembers, setShowMembers] = useState(false)

  useEffect(
    function () {
      setLoading(true)
      fetchUsers(criterion).then((usersList) => {
        setUsers(usersList)
        setLoading(false)
      })
    },
    [search],
  )

  const handleMemberNameSearch = ({
    target,
  }: React.ChangeEvent<HTMLInputElement>) => {
    setSearch(target.value)
  }

  return (
    <>
      <Button
        {...buttonOptions}
        onClick={() => setShowMembers(true)}
        variant="link"
      />
      <Dialog opened={showMembers} onClose={() => setShowMembers(false)}>
        <Dialog.Header className="pb-4 pt-3 pl-5" closeButton>
          <Flex spacing="between" flex="1">
            <Body color="light" text={title} />
          </Flex>
        </Dialog.Header>

        <Dialog.Body className="px-5">
          <Flex orientation="column" align="stretch">
            <TextInput
              onChange={handleMemberNameSearch}
              placeholder="Filter for members"
              value={search}
            />
            <List>
              {users.map((user: ScimObject, index: number) => (
                <ListItem key={`users-${index}`}>
                  <User
                    avatar
                    avatarUrl={get(user, "photos.0.value")}
                    margin="none"
                    name={user.displayName}
                  />
                </ListItem>
              ))}
            </List>
          </Flex>
          <Flex orientation="column" align="center">
            <Button
              key={`load-more-${loading}`}
              flex="1"
              text="Load More"
              variant="link"
            />
            <Caption size="xs" text={`Showing ${users.length} of ${count}`} />
          </Flex>
        </Dialog.Body>
      </Dialog>
    </>
  )
}
