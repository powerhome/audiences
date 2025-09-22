export interface ScimObject {
  id: string
  externalId: string
  displayName: string
  title: string
  photos?: {
    type: "primary" | "thumb"
    value: string
  }[]
  "urn:ietf:params:scim:schemas:extension:authservice:2.0:User"?: {
    role: string
    department: string
    territory: string
    territoryAbbr: string
  }
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
