# frozen_string_literal: true

module Hyrax
  module DepositWizard
    # Wizard context shared by the controller and its views: config, per-request
    # state, the work-type list, the stepper rail, and the work/file forms.
    module Context # rubocop:disable Metrics/ModuleLength
      extend ActiveSupport::Concern

      included do
        helper_method :wizard_config, :wizard_state, :available_work_types,
                      :item_stepper_steps, :stepper_phase, :work_form, :last_deposited,
                      :available_admin_sets, :selected_admin_set_id, :selected_admin_set_name,
                      :uploaded_files, :file_meta_forms, :file_inherits_visibility?,
                      :file_visibility_summaries, :work_visibility_attributes,
                      :file_display_title, :selected_member_collections, :saved_permission_grants,
                      :extra_prefilled?, :selected_parent_title, :collection_display_title
      end

      # The seam downstream apps replace to add container types, suggestions, etc.
      def wizard_config
        Hyku::DepositWizard.config
      end

      def wizard_state
        @wizard_state ||= Hyku::DepositWizard::State.new(session[:deposit_wizard] ||= {})
      end

      def available_work_types
        Hyrax::QuickClassificationQuery.new(current_user).authorized_models
      end

      # A "File detail" step appears only when files were uploaded:
      # type -> upload -> detail -> [file detail] -> review.
      def item_stepper_steps
        stepper_keys.each_with_index.map do |key, i|
          { n: i + 1, label: t("hyku.deposit_wizard.stepper.item.#{key}"), icon: stepper_icon(key) }
        end
      end

      def stepper_icon(key)
        { type: 'fa-list-alt',
          upload: 'fa-cloud-upload',
          detail: 'fa-pencil',
          file_detail: 'fa-file-text-o',
          review: 'fa-check' }.fetch(key.to_sym, 'fa-circle')
      end

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

      def build_work_form
        @form = Hyrax::Forms::ResourceForm.for(resource: work_resource_class.new,
                                               admin_set_id: selected_admin_set_id).prepopulate!
        @form.validate(wizard_state.attributes) if wizard_state.attributes.present?
        @latest_schema_version = Hyrax::FlexibleSchema.current_schema_id.to_f
      end

      def uploaded_files
        @uploaded_files ||= Hyrax::UploadedFile.where(id: wizard_state.uploaded_file_ids)
                                               .index_by { |uf| uf.id.to_s }
                                               .values_at(*wizard_state.uploaded_file_ids).compact
      end

      # A FileSet form per uploaded file, keyed by uploaded-file id, prepopulated
      # from any saved metadata so entered values survive navigating back.
      def file_meta_forms
        @file_meta_forms ||= uploaded_files.index_by { |uf| uf.id.to_s }.transform_values do |uf|
          form = Hyrax::Forms::ResourceForm.for(resource: Hyrax.config.file_set_class.new).prepopulate!
          saved = wizard_state.file_metadata[uf.id.to_s]
          if saved.present?
            form.validate(saved) # restore entered values on Back
          else
            # Default title to the filename
            form.title = [file_display_title(uf)]
          end
          form
        end
      end

      def file_inherits_visibility?(uploaded_file_id)
        saved = wizard_state.file_metadata[uploaded_file_id.to_s]
        saved.nil? || saved['inherit_visibility'] != '0'
      end

      def file_display_title(uploaded_file)
        id = uploaded_file.id.to_s
        entered = Array(wizard_state.file_metadata[id].to_h['title']).find(&:present?)
        return entered if entered.present?

        name = uploaded_file.file&.file&.filename.to_s
        base = File.basename(name, File.extname(name))
        base.tr('_-', '  ').squish.presence&.capitalize || id
      end

      def file_visibility_summaries
        uploaded_files.map do |uf|
          id    = uf.id.to_s
          saved = wizard_state.file_metadata[id].to_h
          attrs = file_inherits_visibility?(id) ? work_visibility_attributes : saved
          { title: Array.wrap(saved['title']).first.presence || uf.file&.file&.filename || id,
            attributes: attrs }
        end
      end

      # Under embargo/lease the visibility populator sets the form's flat
      # `visibility` to the *during* value and stores the details on the
      # `embargo`/`lease` sub-form — so read those back and restore the
      # "embargo"/"lease" selector for #visibility_summary's transitional phrasing.
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

      def selected_admin_set_id
        wizard_state.admin_set_id.presence || default_admin_set_id
      end

      def default_admin_set_id
        Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id.to_s
      rescue StandardError
        available_admin_sets.first&.dig(1)&.to_s
      end

      def selected_admin_set_name
        id = selected_admin_set_id
        available_admin_sets.find { |_label, option_id, *| option_id.to_s == id.to_s }&.first
      end

      def work_resource_class
        chosen = wizard_state.work_type.constantize
        return chosen if chosen < Hyrax::Resource

        Hyrax::ModelRegistry.work_classes.detect do |klass|
          klass < Hyrax::Resource && klass.model_name.param_key == chosen.model_name.param_key
        end || chosen
      end

      # Shown as an inline chooser only when more than one is available.
      def available_admin_sets
        @available_admin_sets ||=
          Hyrax::AdminSetSelectionPresenter.new(admin_sets: admin_sets_for_deposit).select_options
      end

      def admin_sets_for_deposit
        Hyrax::AdminSetService.new(self).search_results(:deposit)
      end

      # A since-deleted collection id is dropped individually rather than failing
      # the whole review render.
      def selected_member_collections
        rows = wizard_state.attributes['member_of_collections_attributes']
        ids = Array.wrap(rows.is_a?(Hash) ? rows.values : rows)
                   .reject { |h| h.is_a?(Hash) && h['_destroy'].to_s == 'true' }
                   .map { |h| h.is_a?(Hash) ? h['id'] : h }.compact.uniq

        ids.filter_map do |id|
          Hyrax.query_service.find_by(id: id)
        rescue Valkyrie::Persistence::ObjectNotFoundError
          nil
        end
      end

      def saved_permission_grants
        rows = wizard_state.attributes['permissions_attributes']
        Array.wrap(rows.is_a?(Hash) ? rows.values : rows)
             .select { |h| h.is_a?(Hash) && h['name'].present? && h['access'].present? }
      end

      def saved_redirect_paths
        rows = wizard_state.attributes['redirects_attributes']
        Array.wrap(rows.is_a?(Hash) ? rows.values : rows)
             .select { |h| h.is_a?(Hash) && h['path'].present? }
      end

      # Read the title, not #to_s: a CollectionResource's #to_s is class+id, and
      # available_collections and find_by return different object types here.
      def collection_display_title(collection)
        Array(collection.title).first
      end

      def selected_parent_title
        return if wizard_state.parent_id.blank?

        Array(Hyrax.query_service.find_by(id: wizard_state.parent_id).title).first
      rescue Valkyrie::Persistence::ObjectNotFoundError
        nil
      end

      # Drives whether the capability's review card renders expanded on load.
      def extra_prefilled?(kind)
        case kind
        when :parent     then wizard_state.parent_id.present?
        when :collection then selected_member_collections.any?
        when :sharing    then saved_permission_grants.any?
        when :redirects  then saved_redirect_paths.any?
        else false
        end
      end

      def eligible_parent_documents(query)
        search = Hyrax::SearchService.new(config: blacklight_config, user_params: { q: query.to_s },
                                          search_builder_class: Hyrax::My::FindWorksSearchBuilder,
                                          scope: self, current_ability: current_ability)
        _, docs = search.search_results do |builder|
          builder.with(q: query.to_s).with_access(:read).rows(20)
          types = eligible_parent_types
          builder.merge(fq: type_filter_query(types)) if types.present?
          builder
        end
        docs
      end

      def eligible_parent_types
        wizard_config.parent_types.presence || available_work_types.map(&:to_s)
      end

      def type_filter_query(type_names)
        clauses = Array(type_names).map { |name| "has_model_ssim:\"#{name}\"" }
        "(#{clauses.join(' OR ')})"
      end

      def last_deposited
        session.delete(:deposit_wizard_last)
      end

      def needs_work_type?(step)
        self.class::STEPS_REQUIRING_WORK_TYPE.include?(step) && wizard_state.work_type.blank?
      end
    end
  end
end
