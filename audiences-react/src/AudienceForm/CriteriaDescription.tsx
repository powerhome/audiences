import React from "react"
import join from "lodash/join"
import map from "lodash/map"
import isEmpty from "lodash/isEmpty"

import { Groups, ScimObject } from "../types"

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
  Titles: "",
  Departments: "in",
  Territories: "from",
}

type CriteriaDescriptionProps = {
  groups?: Groups
}
export function CriteriaDescription({ groups }: CriteriaDescriptionProps) {
  if (!groups || groups.groups) return null

  return (
    <div>
      {"All "}
      {map(Prepositions, (prep, key) =>
        isEmpty(groups[key]) ? null : (
          <React.Fragment key={`groups-${key}`}>
            {` ${prep} `}
            <strong>{toSentence(groups[key])}</strong>
          </React.Fragment>
        ),
      )}
      {"."}
    </div>
  )
}
