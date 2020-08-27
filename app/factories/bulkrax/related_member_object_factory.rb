# frozen_string_literal: true

module Bulkrax
  class RelatedMemberObjectFactory < ObjectFactory
    # NOTE(bkiahstroud): Override to add related_members_attributes
    def permitted_attributes
      %i[related_members_attributes] + super
    end
  end
end
