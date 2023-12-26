import React, { useEffect, useState } from "react"
import get from "lodash/get"
import debounce from "lodash/debounce"
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

import type { GroupCriterion, ScimObject } from "../../types"
import { useAudienceContext } from "../../audiences"
import styles from "./style.module.css"

type MembersModalButtonProps = any & {
  title: React.ReactNode
  criterion?: GroupCriterion
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

  useEffect(() => {
    loadUsers(0).then(setUsers)
  }, [search])

  async function loadUsers(limit: number) {
    setLoading(true)
    const users = await fetchUsers(criterion, search, limit)
    setLoading(false)
    return users
  }

  async function handleLoadMore() {
    const moreUsers = await loadUsers(users.length)
    setUsers((users) => [...users, ...moreUsers])
  }

  function handleMemberNameSearch({
    target,
  }: React.ChangeEvent<HTMLInputElement>) {
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
            <List className={styles.list}>
              {users.map((user: ScimObject, index: number) => (
                <ListItem key={`users-${index}`} padding="xs">
                  <User
                    avatar
                    avatarUrl={get(user, "photos.0.value")}
                    margin="none"
                    name={user.displayName}
                  />
                </ListItem>
              ))}
              <ListItem>
                {users.length < count && (
                  <Button
                    key={`load-more-${loading}`}
                    disabled={loading}
                    flex="1"
                    text="Load More"
                    onClick={handleLoadMore}
                    variant="link"
                  />
                )}
              </ListItem>
            </List>
          </Flex>
          <Flex orientation="column" align="center">
            <Caption size="xs" text={`Showing ${users.length} of ${count}`} />
          </Flex>
        </Dialog.Body>
      </Dialog>
    </>
  )
}
