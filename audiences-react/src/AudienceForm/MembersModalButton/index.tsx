import React, { useEffect, useState } from "react"
import get from "lodash/get"
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
import styles from "./style.module.css"
import { useAudiencesContext } from "../../audiences"

type MembersModalButtonProps = any & {
  criterion?: GroupCriterion
  title: React.ReactNode
  total: number
}
export function MembersModalButton({
  title,
  total,
  criterion,
  ...buttonOptions
}: MembersModalButtonProps) {
  const { fetchUsers } = useAudiencesContext()
  const [loading, setLoading] = useState<boolean>()
  const [current, setUsers] = useState<
    Awaited<ReturnType<typeof fetchUsers>> | undefined
  >()
  const [search, setSearch] = useState("")
  const [showMembers, setShowMembers] = useState(false)

  useEffect(() => {
    if (showMembers) {
      load(0).then(setUsers)
    }
  }, [search, showMembers])

  async function load(offset: number) {
    setLoading(true)
    return fetchUsers(criterion, search, offset).finally(() => {
      setLoading(false)
    })
  }

  async function handleLoadMore() {
    const moreUsers = await load(current!.users.length)
    setUsers((current: any) => ({
      count: moreUsers.count,
      users: [...current!.users, ...moreUsers.users],
    }))
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

        {current && (
          <Dialog.Body className="px-5">
            <Flex orientation="column" align="stretch">
              <TextInput
                onChange={handleMemberNameSearch}
                placeholder="Filter for members"
                value={search}
              />
              <List className={styles.list}>
                {current.users.map((user: ScimObject, index: number) => (
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
                  {current.users.length < current.count && (
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
              <Caption
                size="xs"
                text={`Showing ${current.users.length} of ${total}`}
              />
            </Flex>
          </Dialog.Body>
        )}
      </Dialog>
    </>
  )
}
