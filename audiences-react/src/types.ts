export interface ScimObject {
  id: string
  displayName: string
  photos?: {
    type: "primary" | "thumb"
    value: string
  }[]
}

export interface Groups {
  [resourceType: string]: ScimObject[]
}

export interface GroupCriterion {
  groups?: Groups
  count?: number
}

export interface AudienceContext {
  match_all: boolean
  extra_users: ScimObject[] | null
  criteria: GroupCriterion[]
  count: number
}
