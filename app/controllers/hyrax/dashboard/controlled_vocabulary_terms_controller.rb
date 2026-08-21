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

      # An imported copy has a database row, so find_by! alone would let a term through;
      # its terms are not this tenant's to change. Checked here because the view only
      # hides the button.
      def load_vocabulary
        @vocabulary = Qa::LocalAuthority.find_by!(name: params[:controlled_vocabulary_id])
        return if ControlledVocabularyCatalog.find!(@vocabulary.name).editable?

        raise ActiveRecord::RecordNotFound, "#{@vocabulary.name} does not take terms added here"
      end

      # No :position — the model assigns it, so it cannot be posted.
      def term_params
        params.require(:local_authority_entry).permit(:label, :uri)
      end

      def breadcrumb_trail
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t('hyku.admin.controlled_vocabularies'), main_app.controlled_vocabularies_path
        add_breadcrumb @vocabulary.display_label, main_app.controlled_vocabulary_path(@vocabulary.name)
        # The form route, not request.path: this trail is also drawn when create
        # re-renders the form, and the POST path has no GET to link to.
        add_breadcrumb t('hyku.admin.controlled_vocabulary.new_term_title'),
                       main_app.new_controlled_vocabulary_term_path(@vocabulary.name)
      end
    end
  end
end
