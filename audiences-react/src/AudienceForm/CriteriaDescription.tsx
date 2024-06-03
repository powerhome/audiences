import React from "react"
import { Body, Title } from "playbook-ui"
import { isEmpty, map } from "lodash"

import { Groups } from "../types"
import { toSentence } from "./toSentence"

const Prepositions = {
  Titles: "",
  Departments: "in",
  Territories: "from",
}

type CriteriaDescriptionProps = {
  groups: Groups
}
export function CriteriaDescription({ groups }: CriteriaDescriptionProps) {
  return (
    <div>
      <Body tag="span" text="All" />
      {map(Prepositions, (prep, key) =>
        isEmpty(groups[key]) ? null : (
          <React.Fragment key={`groups-${key}`}>
            <Body tag="span" text={` ${prep} `} />
            <Title tag="span" size={4} text={toSentence(map(groups[key], "displayName"))} />
          </React.Fragment>
        ),
      )}
      <Body tag="span">{"."}</Body>
    </div>
  )
}
