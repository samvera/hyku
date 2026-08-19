# frozen_string_literal: true

module Hyrax
  module Dashboard
    # Adds terms to a vocabulary this tenant manages.
    class ControlledVocabularyTermsController < ApplicationController
      with_themed_layout 'dashboard'

      before_action -> { authorize! :manage, :controlled_vocabularies }
      before_action :load_vocabulary

      def new
        @term = @vocabulary.local_authority_entries.new
        breadcrumb_trail
      end

      def create
        @term = @vocabulary.local_authority_entries.new(term_params)

        if @term.save
          redirect_to main_app.controlled_vocabulary_path(@vocabulary.name),
                      notice: t('hyku.admin.controlled_vocabulary.term_created', label: @term.label)
        else
          breadcrumb_trail
          render :new, status: :unprocessable_entity
        end
      end

      private

      # Only a vocabulary this tenant owns takes new terms. A yaml-backed or imported
      # one has no row to attach them to, and find_by! keeps that a 404 rather than a
      # form that cannot save.
      def load_vocabulary
        @vocabulary = Qa::LocalAuthority.find_by!(name: params[:controlled_vocabulary_id])
      end

      def term_params
        params.require(:local_authority_entry).permit(:label, :uri)
      end

      def breadcrumb_trail
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t('hyku.admin.controlled_vocabularies'), main_app.controlled_vocabularies_path
        add_breadcrumb @vocabulary.display_label, main_app.controlled_vocabulary_path(@vocabulary.name)
        add_breadcrumb t('hyku.admin.controlled_vocabulary.new_term_title'), request.path
      end
    end
  end
end
