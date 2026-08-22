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

      # The whole list is posted, so a reorder is one write rather than one per term.
      def update_order
        @vocabulary.resequence_terms(ordered_ids)

        redirect_to main_app.controlled_vocabulary_path(@vocabulary.name),
                    notice: t('hyku.admin.controlled_vocabulary.order_saved')
      end

      # Retiring is offered in place of deleting, which works cannot survive: they
      # store the term id, so a retired term stops being offered on the deposit form
      # while still resolving for the works citing it.
      def update_status
        # Scoped through the vocabulary, so a term id from another one is not found
        # rather than quietly edited.
        term = @vocabulary.local_authority_entries.find(params[:id])
        term.update!(active: activating?)

        redirect_to main_app.controlled_vocabulary_path(@vocabulary.name),
                    notice: t("hyku.admin.controlled_vocabulary.#{activating? ? 'term_restored' : 'term_retired'}",
                              label: term.label)
      end

      private

      # Required rather than defaulted: casting a missing parameter gives nil, which
      # reads as retiring, so an incomplete request would take a term out of use
      # without asking. `false` is a valid answer, hence require before casting.
      #
      # @raise [ActionController::ParameterMissing] when no state is given
      def activating?
        params.require(:active)
        ActiveModel::Type::Boolean.new.cast(params[:active]).present?
      end

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

      # The order of the posted ids is the order itself: a browser submits fields in
      # document order, and the drag moves the row rather than rewriting a number. So
      # nothing here has to trust a position the page calculated.
      #
      # A nested value is dropped rather than passed on: `term_ids[a]=1` arrives as
      # ActionController::Parameters, which has no #to_i, so it would raise instead of
      # being ignored.
      def ordered_ids
        Array(params[:term_ids]).grep_v(ActionController::Parameters)
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
