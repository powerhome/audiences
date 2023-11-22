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

import type { ScimObject } from "../types"
import { useAudienceContext } from "../audiences"

type MembersModalButtonProps = {
  label: string
  title: React.ReactNode
  count: number
}

export function MembersModalButton({
  title,
  label,
  count,
}: MembersModalButtonProps) {
  const [loading, setLoading] = useState<boolean>()
  const [users, setUsers] = useState<ScimObject[]>([])
  const [search, setSearch] = useState("")
  const { fetchUsers } = useAudienceContext()
  const [showMembers, setShowMembers] = useState(false)

  useEffect(
    function () {
      setLoading(true)
      fetchUsers().then((usersList) => {
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
        onClick={() => setShowMembers(true)}
        padding="none"
        text={label}
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
              {users.map((member: ScimObject, index: number) => (
                <ListItem>
                  <User
                    avatar
                    avatarUrl={get(member, "photos.0.value")}
                    key={index}
                    marginBottom="xs"
                    name={member.displayName}
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
