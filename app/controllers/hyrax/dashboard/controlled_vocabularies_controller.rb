# frozen_string_literal: true

module Hyrax
  module Dashboard
    # Read-only listing of every authority a metadata profile can cite, so staff can
    # find the source key to paste into one.
    class ControlledVocabulariesController < ApplicationController
      with_themed_layout 'dashboard'

      before_action do
        authorize! :view, :controlled_vocabularies
      end

      def index
        @controlled_vocabularies = ControlledVocabularyCatalog.all
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t('hyku.admin.controlled_vocabularies'), request.path
      end

      def show
        @entry = ControlledVocabularyCatalog.find!(params[:id])
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        # main_app, not the bare helper: this controller is namespaced under
        # Hyrax::, so bare url helpers resolve against the Hyrax engine, which does
        # not define this route. The engine's `/files/:id` then swallows it.
        add_breadcrumb t('hyku.admin.controlled_vocabularies'), main_app.controlled_vocabularies_path
        add_breadcrumb @entry.label, request.path
        @terms = ControlledVocabularyCatalog.terms_for(@entry)
      end
    end
  end
end
