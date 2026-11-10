# frozen_string_literal: true

# A source that reads its own records (ExampleSourceUser, ExampleSourceGroup,
# ExampleSourceMembership) and touches no Audiences::ExternalUser, Group or
# GroupMembership. It finds records through the ids Audiences stores
# (Criterion#source_group_ids, Context#source_user_ids).
class FakeSource
  def fetch(resource_type:, query:, start_index:, count:)
    records = search(scope(resource_type), query).offset(start_index).limit(count)

    present(records)
  end

  def groups_of(criterion)
    ExampleSourceGroup.where(id: criterion.source_group_ids)
  end

  def users_matching(groups:)
    groups = groups.to_a
    return ExampleSourceUser.none if groups.empty?

    groups.group_by(&:resource_type).values.reduce(ExampleSourceUser.all) do |users, of_type|
      users.where(id: members_of(of_type))
    end
  end

  def all_users
    ExampleSourceUser.all
  end

  def extra_users_of(context)
    ExampleSourceUser.where(id: context.source_user_ids)
  end

  def present(records)
    records.map do |record|
      shape = { "id" => record.id.to_s, "externalId" => record.id.to_s, "displayName" => record.display_name }

      record.is_a?(ExampleSourceUser) ? shape.slice(*Audiences.exposed_user_attributes) : shape
    end
  end

  def identity_keys(users)
    users.map { |user| user.id.to_s }
  end

  def search_users(users, query)
    search(users, query)
  end

private

  def scope(resource_type)
    if resource_type == "Users"
      ExampleSourceUser.instance_exec(&Audiences.default_users_scope)
    else
      ExampleSourceGroup.where(resource_type: resource_type).instance_exec(&Audiences.default_groups_scope)
    end
  end

  def search(records, query)
    records.where(records.arel_table[:display_name].matches("%#{query}%"))
  end

  def members_of(groups)
    ExampleSourceMembership.where(example_source_group_id: groups.map(&:id)).select(:example_source_user_id)
  end
end
