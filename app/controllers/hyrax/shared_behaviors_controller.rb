module Hyrax
  class SharedBehaviorsController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks

    private

      def after_update_response
        download_stats = WorkDownloadStat.find_by(work_uid: presenter.solr_document.id)
        download_stats.update_attributes(title: presenter.solr_document.title.first) if download_stats
        super
      end
  end
end
