export type AudienceResource = {
  resource_id: string
  resource_type: string
  display: string
  image_url?: string
}

export type AudienceCriteria = {
  count?: number
  resources: AudienceResource[]
}

export type AudienceContext = {
  match_all: boolean
  criteria: AudienceCriteria[]
  resources: AudienceResource[]
  total_members?: number
}
