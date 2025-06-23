# frozen_string_literal: true

class MoveGroupCriterionToCriterionGroups < ActiveRecord::Migration[6.1]
  def up
    Audiences::Criterion.find_each do |criterion|
      next if criterion.groups_json.blank?

      groups = criterion.groups_json.values.flat_map do |scim_groups|
        scim_groups.pluck("id")
      end

      criterion.update!(groups: Audiences::Group.where(scim_id: groups))
    end
  end
end
