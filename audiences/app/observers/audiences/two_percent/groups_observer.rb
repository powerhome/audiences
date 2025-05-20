module Audiences
  module TwoPercent
    class GroupsObserver < ObserverBase
      Audiences.config.group_types.each do |group_type|
        subscribe_to "two_percent.scim.create.#{group_type}"
        subscribe_to "two_percent.scim.replace.#{group_type}"
      end

      def process
      end
    end
  end
end
