# frozen_string_literal: true

module Audiences
  # Transitional coordinator. Only adapters interpret picked references.
  # Phase 4 removes legacy resolution and the second reference from each selection.
  class SelectionResolver
    def initialize(source: Audiences.source, legacy_source: Sources::Legacy.new)
      @source = source
      @legacy_source = legacy_source
    end

    def criterion_groups(resource_type:, references:)
      selections = Array(references).map do |reference|
        arguments = { resource_type: resource_type, references: [reference] }
        CriterionGroup.new(
          group: resolve_one(@legacy_source.resolve_criterion_groups(**arguments)),
          configured_group: resolve_one(@source.resolve_criterion_groups(**arguments))
        )
      end
      selections.uniq { |selection| [selection.group_id, selection.configured_group_id] }
    end

    def extra_users(references:)
      selections = Array(references).map do |reference|
        ContextExtraUser.new(
          external_user: resolve_one(@legacy_source.resolve_extra_users(references: [reference])),
          configured_user: resolve_one(@source.resolve_extra_users(references: [reference]))
        )
      end
      selections.uniq { |selection| [selection.external_user_id, selection.configured_user_id] }
    end

  private

    def resolve_one(records)
      records = records.to_a
      unless records.one?
        raise ActiveRecord::RecordNotFound, "A picked reference must resolve to exactly one record in each source"
      end

      records.first
    end
  end
end
