# frozen_string_literal: true

# Benchmarks resolving an Audiences::Context's users at production-like scale,
# comparing the single-statement criteria matching (Context#users) against the
# previous approach that loaded criteria and groups before building the query.
#
# Seeds data inside a transaction that is rolled back, so it leaves the database
# untouched. Run from the gem root against the test database:
#
#   RAILS_ENV=test bin/rails runner benchmarks/context_users.rb
#
# Tune the dataset with environment variables (defaults mirror the Connect room
# that prompted SHD-2148):
#
#   USERS=5400 CRITERIA=7 GROUPS_PER_CRITERION=2 EXTRA_USERS=10 ITERATIONS=20
#   EXPLAIN=1 also prints the query plan for the single-statement query.
#
# Temporary: remove once Context#users performance has been validated at scale.

# Seeding skips validations for speed, and this throwaway script favors
# readability over method size limits.
# rubocop:disable Rails/SkipsModelValidations, Metrics/MethodLength, Metrics/AbcSize

USERS = Integer(ENV.fetch("USERS", "5400"))
CRITERIA = Integer(ENV.fetch("CRITERIA", "7"))
GROUPS_PER_CRITERION = Integer(ENV.fetch("GROUPS_PER_CRITERION", "2"))
EXTRA_USERS = Integer(ENV.fetch("EXTRA_USERS", "10"))
ITERATIONS = Integer(ENV.fetch("ITERATIONS", "20"))

# Every user belongs to one group of each type, as in the SCIM directory.
GROUP_COUNTS = { "Titles" => 300, "Departments" => 60, "Territories" => 40, "Roles" => 30 }.freeze

def insert_groups
  now = Time.current
  rows = GROUP_COUNTS.flat_map do |type, count|
    Array.new(count) do |i|
      id = "bench-#{type}-#{i}"
      { scim_id: id, external_id: id, display_name: "#{type} #{i}", resource_type: type,
        created_at: now, updated_at: now }
    end
  end
  Audiences::Group.insert_all(rows)
  Audiences::Group.where("scim_id LIKE 'bench-%'").group_by(&:resource_type)
end

def insert_users(groups_by_type)
  now = Time.current
  Audiences::ExternalUser.insert_all(Array.new(USERS) do |i|
    { scim_id: "bench-#{i}", user_id: "bench-#{i}", display_name: "User #{i}",
      data: { "id" => "bench-#{i}" }, active: true, created_at: now, updated_at: now }
  end)

  user_ids = Audiences::ExternalUser.where("scim_id LIKE 'bench-%'").pluck(:id)
  memberships = user_ids.flat_map do |user_id|
    groups_by_type.values.map do |groups|
      { external_user_id: user_id, group_id: groups.sample.id, created_at: now, updated_at: now }
    end
  end
  memberships.each_slice(10_000) { |batch| Audiences::GroupMembership.insert_all(batch) }
  user_ids
end

def build_context(groups_by_type, user_ids)
  context = ExampleOwner.create!(name: "Benchmark").members_context
  types = groups_by_type.keys
  criteria = Array.new(CRITERIA) do |i|
    # Mix single-type criteria (like Connect's title lists) with multi-type ones.
    criterion_types = i.even? ? [types.first] : types.sample(2)
    groups = criterion_types.flat_map { |type| groups_by_type[type].sample(GROUPS_PER_CRITERION) }
    Audiences::Criterion.new(groups: groups)
  end
  extra_users = Audiences::ExternalUser.where(id: user_ids.sample(EXTRA_USERS))
  context.update!(criteria: criteria, extra_users: extra_users)
  Audiences::Context.find(context.id)
end

# The resolution Context#users used before SHD-2148: criteria and their groups
# loaded into Ruby, then combined into one query.
def legacy_users(context)
  criteria_scopes = context.criteria.map do |criterion|
    groups = criterion.groups.to_a
    next Audiences::ExternalUser.none if groups.empty?

    groups.group_by(&:resource_type).values.reduce(Audiences::ExternalUser.all) do |scope, type_groups|
      scope.members_of(type_groups)
    end
  end
  matching_criteria = criteria_scopes.reduce(Audiences::ExternalUser.none) { |scope, other| scope.or(other) }

  Audiences::ExternalUser.where(id: context.extra_users.select(:id))
                         .or(matching_criteria)
                         .instance_exec(&Audiences.default_users_scope)
end

def count_queries(&block)
  count = 0
  counter = ->(*, payload) { count += 1 unless payload[:cached] || payload[:name] == "SCHEMA" }
  ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
  count
end

def measure(label, &block)
  ActiveRecord::Base.uncached do
    queries = count_queries(&block) # also warms up
    timings = Array.new(ITERATIONS) do
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      yield
      (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000
    end.sort
    format("%-22<label>s median %<median>8.2fms  p95 %<p95>8.2fms  max %<max>8.2fms  queries %<queries>d",
           label: label, median: timings[timings.size / 2], p95: timings[(timings.size * 0.95).floor - 1],
           max: timings.last, queries: queries)
  end
end

ActiveRecord::Base.transaction do
  puts "Seeding #{USERS} users, #{CRITERIA} criteria x #{GROUP_COUNTS.size} group types " \
       "(#{ActiveRecord::Base.connection.adapter_name})..."
  groups_by_type = insert_groups
  user_ids = insert_users(groups_by_type)
  context = build_context(groups_by_type, user_ids)

  current = context.users.pluck(:id).sort
  legacy = legacy_users(context).pluck(:id).sort
  raise "Results differ: current=#{current.size} legacy=#{legacy.size}" unless current == legacy

  puts "Both approaches resolve #{current.size} users.\n\n"
  # Reload the context each run so neither approach reuses loaded criteria.
  puts measure("single statement") { Audiences::Context.find(context.id).users.to_a }
  puts measure("legacy (load + match)") { legacy_users(Audiences::Context.find(context.id)).to_a }

  if ENV["EXPLAIN"]
    puts "\nQuery plan (single statement):"
    puts context.users.explain
  end

  raise ActiveRecord::Rollback
end

# rubocop:enable Rails/SkipsModelValidations, Metrics/MethodLength, Metrics/AbcSize
