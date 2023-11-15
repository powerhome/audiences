export interface ScimObject {
  id: string
  displayName: string
  photos?: {
    type: "primary" | "thumb"
    value: string
  }[]
}

export interface GroupCriteria {
  [resourceType: string]: ScimObject[]
}

export interface AudienceCriteria {
  groups?: GroupCriteria[]
}

export interface AudienceContext {
  match_all: boolean
  extra_users: ScimObject[] | null
  criteria: AudienceCriteria
  total_members?: number
}
