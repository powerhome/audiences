// import type { AudienceResource } from "../types"
import join from "lodash/join"
import map from "lodash/map"
// import { AudienceContextInput } from "."
import { isEmpty } from "lodash"
import React from "react"
import { GroupCriteria } from "../types"
import { ScimObject } from "../types"

function toSentence(resources: ScimObject[]) {
  const names = map(resources, "displayName")

  if (names.length == 1) {
    return names
  } else if (names.length == 2) {
    return join(names, " and ")
  } else {
    const lastOne = names.pop()

    return `${join(names, ", ")}, and ${lastOne}`
  }
}

const Prepositions = {
  Title: "",
  Department: "in",
  Territory: "from",
}

type CriteriaDescriptionProps = {
  criteria?: GroupCriteria
}
export const CriteriaDescription = ({ criteria }: CriteriaDescriptionProps) => {
  if (!criteria) return null

  return (
    <div>
      {"All "}
      {map(Prepositions, (prep, key) =>
        isEmpty(criteria[key]) ? null : (
          <React.Fragment key={`criteria-${criteria.id}-${key}`}>
            {` ${prep} `}
            <strong>{toSentence(criteria[key])}</strong>
          </React.Fragment>
        ),
      )}
      {"."}
    </div>
  )
}
