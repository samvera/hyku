# frozen_string_literal: true

module Hyrax
  module DepositWizard
    # Wizard context shared by the controller and its views: the active config,
    # per-request state, the work-type list, the stepper rail, and the work form.
    # These are cohesive view/state helpers for one feature, so the module runs
    # past the default length limit; splitting it would scatter related helpers.
    module Context # rubocop:disable Metrics/ModuleLength
      extend ActiveSupport::Concern

      included do
        helper_method :wizard_config, :wizard_state, :available_work_types,
                      :item_stepper_steps, :stepper_phase, :work_form, :last_deposited,
                      :available_admin_sets, :selected_admin_set_id, :selected_admin_set_name,
                      :uploaded_files, :file_meta_forms, :file_inherits_visibility?,
                      :file_visibility_summaries, :work_visibility_attributes
      end

      # The seam downstream apps replace to add container types, suggestions, etc.
      def wizard_config
        Hyku::DepositWizard.config
      end

      def wizard_state
        @wizard_state ||= Hyku::DepositWizard::State.new(session[:deposit_wizard] ||= {})
      end

      # The work types the current user may create, exactly as the stock deposit
      # chooser lists them (tenant- and profile-filtered).
      def available_work_types
        Hyrax::QuickClassificationQuery.new(current_user).authorized_models
      end

      # Stepper rail for the single-item flow. A "File detail" step appears only
      # when files were uploaded (matching the prototype's dynamic step sets):
      # type -> upload -> detail -> [file detail] -> review.
      def item_stepper_steps
        stepper_keys.each_with_index.map { |key, i| { n: i + 1, label: t("hyku.deposit_wizard.stepper.item.#{key}") } }
      end

      # The active step's zero-based index in the current step set, so views ask
      # for their position by name rather than hardcoding a number that shifts
      # when the optional file-detail step is present.
      def stepper_phase(step_key)
        stepper_keys.index(step_key.to_sym) || -1
      end

      def stepper_keys
        keys = %i[type upload detail]
        keys << :file_detail if wizard_state.uploaded_file_ids.any?
        keys << :review
        keys
      end

      def work_form
        @form
      end

      # Build the ResourceForm for the chosen work type, re-validating any values
      # entered on a prior visit so the fields render prepopulated. Passing
      # admin_set_id to +ResourceForm.for+ applies its contexts during form init
      # (in flexible mode those contexts determine which fields the form exposes),
      # which is the same lifecycle point the stock works controller uses.
      def build_work_form
        @form = Hyrax::Forms::ResourceForm.for(resource: work_resource_class.new,
                                               admin_set_id: selected_admin_set_id).prepopulate!
        @form.validate(wizard_state.attributes) if wizard_state.attributes.present?
        # The flexible metadata form's shared/_schema_version widget reads this
        # ivar (stock sets it in a new/edit before_action, which the wizard lacks).
        @latest_schema_version = Hyrax::FlexibleSchema.current_schema_id.to_f
      end

      # The uploaded files awaiting deposit, in the order they will be attached,
      # for the per-file metadata step.
      def uploaded_files
        @uploaded_files ||= Hyrax::UploadedFile.where(id: wizard_state.uploaded_file_ids)
                                               .index_by { |uf| uf.id.to_s }
                                               .values_at(*wizard_state.uploaded_file_ids).compact
      end

      # A FileSet form per uploaded file, prepopulated from any saved per-file
      # metadata, keyed by uploaded-file id. Its terms are profile-driven
      # (file_set_metadata); rendering it inside a per-file-namespaced form
      # reuses Hyrax's own field and visibility partials.
      def file_meta_forms
        @file_meta_forms ||= uploaded_files.index_by { |uf| uf.id.to_s }.transform_values do
          Hyrax::Forms::ResourceForm.for(resource: Hyrax.config.file_set_class.new)
        end
      end

      # Whether a file currently inherits the work's visibility (the default).
      def file_inherits_visibility?(uploaded_file_id)
        saved = wizard_state.file_metadata[uploaded_file_id.to_s]
        saved.nil? || saved['inherit_visibility'] != '0'
      end

      # Per-file summary rows for the review step: each uploaded file's display
      # title and its *effective* visibility attributes (its own when it does not
      # inherit and one was chosen, otherwise the work's), so reviewers see exactly
      # what each file will be deposited as. The attributes hash carries the
      # embargo/lease fields too, so #visibility_summary can render the transitional
      # phrasing rather than just the base visibility string.
      def file_visibility_summaries
        uploaded_files.map do |uf|
          id    = uf.id.to_s
          saved = wizard_state.file_metadata[id].to_h
          attrs = file_inherits_visibility?(id) ? work_visibility_attributes : saved
          # Title is multi-valued; display the first entry, falling back to the
          # file's label/filename — mirroring the app's title-then-label convention
          # (SolrDocument#title_or_label, FileSetPresenter#first_title).
          { title: Array.wrap(saved['title']).first.presence || uf.file&.file&.filename || id,
            attributes: attrs }
        end
      end

      # The work-level visibility attributes as a string-keyed hash for the review
      # summary. Under embargo/lease the form's `visibility` is set to the *during*
      # value by the visibility populator, and the transitional details live on the
      # `embargo`/`lease` sub-form — so read those and restore the "embargo"/"lease"
      # selector so #visibility_summary renders the "X until <date>, then Y" phrase.
      def work_visibility_attributes
        embargo = work_form.try(:embargo)
        lease   = work_form.try(:lease)
        if embargo&.embargo_release_date.present?
          { 'visibility' => 'embargo',
            'visibility_during_embargo' => embargo.visibility_during_embargo,
            'embargo_release_date' => embargo.embargo_release_date,
            'visibility_after_embargo' => embargo.visibility_after_embargo }
        elsif lease&.lease_expiration_date.present?
          { 'visibility' => 'lease',
            'visibility_during_lease' => lease.visibility_during_lease,
            'lease_expiration_date' => lease.lease_expiration_date,
            'visibility_after_lease' => lease.visibility_after_lease }
        else
          { 'visibility' => (work_form.visibility if work_form.respond_to?(:visibility)) }
        end
      end

      # The admin set to deposit into: the user's explicit choice, else the
      # default admin set (matching the stock deposit modal's preselection).
      def selected_admin_set_id
        wizard_state.admin_set_id.presence || default_admin_set_id
      end

      def default_admin_set_id
        Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id.to_s
      rescue StandardError
        available_admin_sets.first&.dig(1)&.to_s
      end

      # The display name of the selected admin set, for the review destination.
      def selected_admin_set_name
        id = selected_admin_set_id
        available_admin_sets.find { |_label, option_id, *| option_id.to_s == id.to_s }&.first
      end

      # The chooser lists ActiveFedora model names, but the form needs the
      # Valkyrie resource class. Resolve by shared param_key against the
      # registered Valkyrie work classes (no Wings), falling back to the chosen
      # class when no Valkyrie class is registered.
      def work_resource_class
        chosen = wizard_state.work_type.constantize
        return chosen if chosen < Hyrax::Resource

        Hyrax::ModelRegistry.work_classes.detect do |klass|
          klass < Hyrax::Resource && klass.model_name.param_key == chosen.model_name.param_key
        end || chosen
      end

      # The admin sets the current user may deposit into, as selection options.
      # Shown as an inline chooser only when more than one is available.
      def available_admin_sets
        @available_admin_sets ||=
          Hyrax::AdminSetSelectionPresenter.new(admin_sets: admin_sets_for_deposit).select_options
      end

      def admin_sets_for_deposit
        Hyrax::AdminSetService.new(self).search_results(:deposit)
      end

      # The just-deposited work info, stashed for the done screen and read once.
      def last_deposited
        session.delete(:deposit_wizard_last)
      end

      def needs_work_type?(step)
        self.class::STEPS_REQUIRING_WORK_TYPE.include?(step) && wizard_state.work_type.blank?
      end
    end
  end
end
