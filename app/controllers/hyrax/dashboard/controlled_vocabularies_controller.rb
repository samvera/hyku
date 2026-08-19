# frozen_string_literal: true

module Hyrax
  module Dashboard
    # Lists every authority a metadata profile can cite, so staff can find the source
    # key to paste into one, and creates the vocabularies this tenant manages.
    class ControlledVocabulariesController < ApplicationController
      with_themed_layout 'dashboard'

      before_action -> { authorize! :view, :controlled_vocabularies }, only: %i[index show]
      before_action -> { authorize! :manage, :controlled_vocabularies }, only: %i[new create]

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

      def new
        @controlled_vocabulary = Qa::LocalAuthority.new
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t('hyku.admin.controlled_vocabularies'), main_app.controlled_vocabularies_path
        add_breadcrumb t('hyku.admin.controlled_vocabulary.new_title'), request.path
      end

      def create
        @controlled_vocabulary = Qa::LocalAuthority.new(controlled_vocabulary_params)

        if @controlled_vocabulary.save
          redirect_to main_app.controlled_vocabulary_path(@controlled_vocabulary.name),
                      notice: t('hyku.admin.controlled_vocabulary.created',
                                name: @controlled_vocabulary.display_label)
        else
          add_breadcrumb t(:'hyrax.controls.home'), root_path
          add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
          add_breadcrumb t('hyku.admin.controlled_vocabularies'), main_app.controlled_vocabularies_path
          add_breadcrumb t('hyku.admin.controlled_vocabulary.new_title'), request.path
          render :new, status: :unprocessable_entity
        end
      end

      private

      # No :name — it is derived from the label on create, and a metadata profile
      # cites it, so staff do not get to set or change it.
      def controlled_vocabulary_params
        params.require(:local_authority).permit(:label, :description)
      end
    end
  end
end
