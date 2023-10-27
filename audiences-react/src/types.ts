export interface GroupCriteria {
  [resourceType: string]: ScimObject[]
}

export interface AudienceCriteria {
  users?: ScimObject[]
  groups?: GroupCriteria
}

export interface AudienceContext {
  match_all: boolean
  criteria: AudienceCriteria
  total_members?: number
}

export interface ScimObject {
  id: string
  displayName: string
  photos?: {
    type: "primary" | "thumb"
    value: string
  }[]
}
