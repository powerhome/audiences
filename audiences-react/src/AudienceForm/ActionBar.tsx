import { Flex, Button } from "playbook-ui";
import { useAudiencesContext } from "../audiences";

export function ActionBar() {
  const { loading, save, isDirty, reset } = useAudiencesContext();

  return (
    <Flex justify="between" marginTop="md">
      <Button
        disabled={!isDirty()}
        text="Save"
        htmlType="submit"
        loading={loading}
        onClick={() => save()} />

      {isDirty() && (
        <Button
          marginLeft="sm"
          text="Cancel"
          variant="link"
          htmlType="reset"
          onClick={() => reset()} />
      )}
    </Flex>
  );
}
