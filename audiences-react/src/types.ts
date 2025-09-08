export interface ScimObject {
  id: string
  externalId: string
  displayName: string
  photos?: {
    type: "primary" | "thumb"
    value: string
  }[]
  [key: string]: any
}

export interface Groups {
  [resourceType: string]: ScimObject[]
}

export interface GroupCriterion {
  id?: number
  groups: Groups
  count?: number
}

export interface AudienceContext {
  match_all: boolean
  extra_users: ScimObject[] | null
  criteria: GroupCriterion[]
  count: number
}
