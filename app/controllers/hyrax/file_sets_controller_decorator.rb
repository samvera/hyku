# frozen_string_literal: true

# OVERRIDE: Hyrax v5.3.0
# - inject the show theme's views so the file set show page gets the theme's
#   chrome, the way the work show page already does
# - name the file by its title in the "has been updated" notice; a Valkyrie
#   file set prints as "Hyrax::FileSet: <id>"

module Hyrax
  module FileSetsControllerDecorator
    extend ActiveSupport::Concern

    include Hyku::ChromeShowThemesBehavior

    private

    def after_update_response
      return super unless request.format.html?

      name = Array(curation_concern.try(:title)).first.presence || curation_concern.to_s
      link_to_file = view_context.link_to(name, [main_app, curation_concern])
      redirect_to [main_app, curation_concern], notice: view_context.t('hyrax.file_sets.asset_updated_flash.message', link_to_file:)
    end
  end
end

Hyrax::FileSetsController.prepend(Hyrax::FileSetsControllerDecorator)
