# frozen_string_literal: true

##
# OVERRIDE Hyrax 3.5.0; when Hyrax hits v4.0.0 we can remove this.
# @see https://github.com/samvera/hyrax/pull/5972
module Hyrax
  module My
    module WorksControllerDecorator
      def collection_service
        cloned = clone
        cloned.params = {}
        Hyrax::CollectionsService.new(cloned)
      end
    end
  end
end

Hyrax::My::WorksController.prepend(Hyrax::My::WorksControllerDecorator)
