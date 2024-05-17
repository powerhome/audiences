import React from "react"
import map from "lodash/map"
import isEmpty from "lodash/isEmpty"

import { Groups } from "../types"
import { toSentence } from "./toSentence"

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
            <strong>{toSentence(map(groups[key], "displayName"))}</strong>
          </React.Fragment>
        ),
      )}
      {"."}
    </div>
  )
}
