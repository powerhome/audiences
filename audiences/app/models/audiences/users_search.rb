# frozen_string_literal: true

module Audiences
  class UsersSearch
    DEFAULT_LIMIT = 20

    def initialize(query:, limit: nil, offset: 0, scope: ExternalUser)
      @scope = scope
      @query = query
      @limit = limit || DEFAULT_LIMIT
      @offset = offset
    end

    def as_json(...)
      {
        users: users.as_json(...),
        count: count,
      }
    end

    delegate :count, to: :result

    def users
      @users ||= result.limit(@limit).offset(@offset)
    end

  private

    def result
      @result ||= if data_column?
                    # Legacy ExternalUser: search JSON data field
                    @scope.where("#{data_attribute_query} LIKE ?", "%#{@query}%")
                  else
                    # Configured models: search display_name and group names
                    search_configured_users
                  end
    end

    def data_column?
      model_class.column_names.include?("data")
    end

    def search_configured_users
      # Search user's display_name and associated group display_names
      # Equivalent to searching JSON blob that contains group info
      @scope.left_joins(:groups)
            .where("#{user_table_name}.display_name LIKE ? OR #{group_table_name}.display_name LIKE ?",
                   "%#{@query}%", "%#{@query}%")
            .distinct
    end

    def model_class
      @scope.respond_to?(:klass) ? @scope.klass : @scope
    end

    def user_table_name
      model_class.table_name
    end

    def group_table_name
      # Get the associated group model's table name
      model_class.reflect_on_association(:groups).klass.table_name
    end

    def data_attribute_query
      case @scope.connection.adapter_name
      when "PostgreSQL" then "CAST(data AS TEXT)"
      else "CAST(data AS CHAR)"
      end
    end
  end
end
