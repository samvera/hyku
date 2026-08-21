# frozen_string_literal: true

module Hyrax
  module Dashboard
    # Bulk-imports terms into a vocabulary this tenant manages. create renders a
    # review of what the file would change; confirm re-parses the same file
    # (carried in a hidden field) and applies it, so nothing is stored
    # server-side between the two steps and nothing is saved before confirm.
    class ControlledVocabularyImportsController < ApplicationController
      with_themed_layout 'dashboard'

      before_action -> { authorize! :manage, :controlled_vocabularies }
      before_action :load_vocabulary

      def new
        breadcrumb_trail
      end

      def create
        file = params[:file]
        return upload_problem(t('hyku.admin.controlled_vocabulary.import.file_missing')) unless file.respond_to?(:read)
        return upload_problem(t('hyku.admin.controlled_vocabulary.import.file_too_large')) if
          file.size > ControlledVocabularyImport::MAX_BYTES

        review(file.read, file.original_filename)
      end

      def confirm
        content = decode_payload
        return if performed?
        # create already refused an oversized upload; a hand-built confirm POST
        # must not get past the same cap.
        return upload_problem(t('hyku.admin.controlled_vocabulary.import.file_too_large')) if
          content.bytesize > ControlledVocabularyImport::MAX_BYTES

        import = build_import(content, params[:filename])
        if params[:state_digest] != import.plan.state_digest
          flash.now[:alert] = t('hyku.admin.controlled_vocabulary.import.stale')
          render_review(import, content)
        elsif import.plan.valid? && import.plan.changes?
          apply(import)
        else
          render_review(import, content)
        end
      end

      private

      def apply(import)
        import.apply!
        redirect_to main_app.controlled_vocabulary_path(@vocabulary.name), notice: applied_notice(import.plan)
      end

      def applied_notice(plan)
        return t('hyku.admin.controlled_vocabulary.import.applied_reordered') if
          plan.additions.empty? && plan.updates.empty?

        t('hyku.admin.controlled_vocabulary.import.applied',
          additions: plan.additions.size, updates: plan.updates.size)
      end

      def review(content, filename)
        import = build_import(content, filename)
        # A file the parser could get no rows out of goes back to the upload
        # form; a readable file with bad rows gets the review page, which lists
        # them and withholds the confirm button.
        if import.plan.errors.any? && import.plan.additions.empty? && import.plan.updates.empty? &&
           import.plan.unchanged_count.zero?
          upload_problem(import.plan.errors)
        else
          render_review(import, content, filename)
        end
      end

      def render_review(import, content, filename = params[:filename])
        @plan = import.plan
        @payload = Base64.strict_encode64(content)
        @filename = filename
        breadcrumb_trail
        render :review
      end

      def build_import(content, filename)
        ControlledVocabularyImport.new(content: content, filename: filename, vocabulary: @vocabulary)
      end

      def upload_problem(messages)
        flash.now[:alert] = Array(messages).join(' ')
        breadcrumb_trail
        render :new, status: :unprocessable_entity
      end

      def decode_payload
        Base64.strict_decode64(params[:payload].to_s)
      rescue ArgumentError
        redirect_to main_app.new_controlled_vocabulary_import_path(@vocabulary.name),
                    alert: t('hyku.admin.controlled_vocabulary.import.payload_invalid')
        nil
      end

      # Only a vocabulary this tenant owns takes imports: a yaml-backed one has
      # no rows to update, and an imported copy (mesh) would be clobbered here
      # and again by its next scheduled import.
      def load_vocabulary
        entry = ControlledVocabularyCatalog.find!(params[:controlled_vocabulary_id])
        raise ActiveRecord::RecordNotFound, "#{entry.source_key} does not accept imports" unless entry.editable?

        @vocabulary = entry.vocabulary
      end

      def breadcrumb_trail
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t('hyku.admin.controlled_vocabularies'), main_app.controlled_vocabularies_path
        add_breadcrumb @vocabulary.display_label, main_app.controlled_vocabulary_path(@vocabulary.name)
        # The form route, not request.path: this trail is also drawn when create
        # and confirm re-render, and their POST paths have no GET to link to.
        add_breadcrumb t('hyku.admin.controlled_vocabulary.import.title'),
                       main_app.new_controlled_vocabulary_import_path(@vocabulary.name)
      end
    end
  end
end
