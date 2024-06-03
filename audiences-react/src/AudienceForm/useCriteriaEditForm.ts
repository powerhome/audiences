import { useState } from "react";
import { useFieldArray, UseFormReturn } from "react-hook-form";
import { every, isEmpty, keyBy, mapValues, omitBy } from "lodash";
import { AudienceContext, GroupCriterion } from "../types";

const validateCriteria = (criteria: GroupCriterion[]) => every(criteria, validateCriterion);
const validateCriterion = ({ groups }: GroupCriterion) => !isEmpty(omitBy(groups, isEmpty));
type UseCriteriaEditFormType = {
  form: UseFormReturn<AudienceContext>;
  groupResources: string[];
};

export function useCriteriaEditForm({ form, groupResources }: UseCriteriaEditFormType) {
  const [currentEditing, setCurrentEditing] = useState<number | undefined>();
  const { remove, append: appendCriteria, fields: currentCriteria } = useFieldArray({
    name: "criteria",
    control: form.control,
    rules: { validate: validateCriteria },
  });

  const addNewCriteria = () => {
    const emptyCriteria = mapValues(keyBy(groupResources), () => []);
    appendCriteria({ groups: emptyCriteria });
    setCurrentEditing(currentCriteria.length);
  };
  const removeCriteria = (index: number) => {
    if (confirm("Remove criteria?")) {
      remove(index);
    }
  };
  const editCriteria = (index: number) => {
    setCurrentEditing(index);
  };
  const closeCriteria = () => {
    if (!form.formState.isValid) {
      remove(currentEditing);
    }
    setCurrentEditing(undefined);
  };

  return { currentEditing, addNewCriteria, editCriteria, removeCriteria, closeCriteria };
}
