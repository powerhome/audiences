import { useFormContext } from "react-hook-form"
import { Button, Card, Flex } from "playbook-ui"

import { Header } from "./Header"

type MainProps = {
  total: number
  name: string
  children: React.ReactNode
}

export function AllToggle({ total, name, children }: MainProps) {
  const { formState, watch } = useFormContext()
  const all = watch(name)

  return (
    <Card margin="xs" padding="xs">
      <Card.Header headerColor={all ? "none" : "white"}>
        <Header name={name} total={total} />
      </Card.Header>

      <Card.Body>
        <Flex orientation="column" align="stretch">
          {all || children}

          <Flex justify="between" marginTop="md">
            <Button
              disabled={
                !formState.isDirty ||
                !formState.isValid ||
                formState.isSubmitting
              }
              loading={formState.isSubmitting}
              text="Save"
              htmlType="submit"
            />

            {formState.isDirty && (
              <Button
                marginLeft="sm"
                text="Cancel"
                variant="link"
                htmlType="reset"
              />
            )}
          </Flex>
        </Flex>
      </Card.Body>
    </Card>
  )
}
