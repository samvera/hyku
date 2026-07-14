# frozen_string_literal: true

module Hyku
  module DepositWizard
    # Request-scoped view-model for the guided deposit wizard: the controller and
    # views share one object (+deposit_wizard.work_form+) rather than a pile of
    # global helper methods. It composes Config and State and delegates request
    # primitives to the controller context (some Hyrax services need it as scope).
    class Presenter # rubocop:disable Metrics/ClassLength
      delegate :current_user, :current_ability, :session, :params, :main_app,
               :blacklight_config, to: :context

      def initialize(context)
        @context = context
      end

      def config
        Hyku::DepositWizard.config
      end

      def state
        @state ||= State.new(session[:deposit_wizard] ||= {})
      end

      def available_work_types
        Hyrax::QuickClassificationQuery.new(current_user).authorized_models
      end

      # A "File detail" step appears only when files were uploaded:
      # type -> upload -> detail -> [file detail] -> review.
      def item_stepper_steps
        stepper_keys.each_with_index.map do |key, i|
          { n: i + 1, label: I18n.t("hyku.deposit_wizard.stepper.item.#{key}"), icon: stepper_icon(key) }
        end
      end

      def stepper_icon(key)
        { parent: 'fa-sitemap',
          type: 'fa-list-alt',
          upload: 'fa-cloud-upload',
          detail: 'fa-pencil',
          file_detail: 'fa-file-text-o',
          review: 'fa-check' }.fetch(key.to_sym, 'fa-circle')
      end

      def stepper_phase(step_key)
        stepper_keys.index(step_key.to_sym) || -1
      end

      def stepper_keys
        keys = []
        keys << :parent if state.path == 'add'
        keys += %i[type upload detail]
        keys << :file_detail if state.uploaded_file_ids.any?
        keys << :review
        keys
      end

      attr_reader :work_form

      def build_work_form
        @work_form = Hyrax::Forms::ResourceForm.for(resource: work_resource_class.new,
                                                    admin_set_id: selected_admin_set_id).prepopulate!
        @work_form.validate(state.attributes) if state.attributes.present?
        @latest_schema_version = Hyrax::FlexibleSchema.current_schema_id.to_f
      end

      def uploaded_files
        @uploaded_files ||= Hyrax::UploadedFile.where(id: state.uploaded_file_ids)
                                               .index_by { |uf| uf.id.to_s }
                                               .values_at(*state.uploaded_file_ids).compact
      end

      # A FileSet form per uploaded file, keyed by uploaded-file id, prepopulated
      # from any saved metadata so entered values survive navigating back.
      def file_meta_forms
        @file_meta_forms ||= uploaded_files.index_by { |uf| uf.id.to_s }.transform_values do |uf|
          form = Hyrax::Forms::ResourceForm.for(resource: Hyrax.config.file_set_class.new).prepopulate!
          saved = state.file_metadata[uf.id.to_s]
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
        saved = state.file_metadata[uploaded_file_id.to_s]
        saved.nil? || saved['inherit_visibility'] != '0'
      end

      def file_display_title(uploaded_file)
        id = uploaded_file.id.to_s
        entered = Array(state.file_metadata[id].to_h['title']).find(&:present?)
        return entered if entered.present?

        name = uploaded_file.file&.file&.filename.to_s
        base = File.basename(name, File.extname(name))
        base.tr('_-', '  ').squish.presence&.capitalize || id
      end

      def file_visibility_summaries
        uploaded_files.map do |uf|
          id    = uf.id.to_s
          saved = state.file_metadata[id].to_h
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
        state.admin_set_id.presence || default_admin_set_id
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
        chosen = state.work_type.constantize
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
        Hyrax::AdminSetService.new(context).search_results(:deposit)
      end

      # Keep the presenter's data-* hash on each option: the visibility component
      # enforces those visibility/release rules downstream on the details form.
      def admin_set_options_for_display
        @admin_set_options_for_display ||= begin
          docs = admin_sets_for_deposit
          templates = Hyrax::PermissionTemplate.where(source_id: docs.map { |d| d.id.to_s }).to_a
          docs.map do |doc|
            template = templates.find { |t| t.source_id == doc.id.to_s }
            entry = Hyrax::AdminSetSelectionPresenter::OptionsEntry.new(admin_set: doc, permission_template: template)
            label, id, data = entry.result
            { id: id, label: label, data: data,
              description: Array(doc.try(:description)).first.presence,
              workflow: template&.active_workflow&.label.presence }
          end
        end
      end

      def multiple_admin_sets?
        admin_set_options_for_display.size > 1
      end

      def show_relationship_paths?
        config.container? || config.enable_parent_connect
      end

      # item_start is only worth showing when it has a sub-flow to choose between
      # (guided suggestions or batch); otherwise skip straight to the type chooser.
      def item_flow_entry_step
        item_start_offers_choice? ? 'item_start' : 'known_type'
      end

      def item_start_offers_choice?
        config.enable_batch || config.suggestions.present?
      end

      def known_type_back_step
        return 'select_parent' if state.path == 'add'
        return 'item_start' if item_start_offers_choice?

        nil # start screen
      end

      # A since-deleted collection id is dropped individually rather than failing
      # the whole review render.
      def selected_member_collections
        rows = state.attributes['member_of_collections_attributes']
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
        rows = state.attributes['permissions_attributes']
        Array.wrap(rows.is_a?(Hash) ? rows.values : rows)
             .select { |h| h.is_a?(Hash) && h['name'].present? && h['access'].present? }
      end

      def saved_redirect_paths
        rows = state.attributes['redirects_attributes']
        Array.wrap(rows.is_a?(Hash) ? rows.values : rows)
             .select { |h| h.is_a?(Hash) && h['path'].present? }
      end

      # Read the title, not #to_s: a CollectionResource's #to_s is class+id, and
      # available_collections and find_by return different object types here.
      def collection_display_title(collection)
        Array(collection.title).first
      end

      def selected_parent_title
        selected_parent&.dig(:title)
      end

      # The chosen parent's human model name + title (one query). nil when unset
      # or since-deleted.
      def selected_parent
        return if state.parent_id.blank?

        @selected_parent ||= begin
          work = Hyrax.query_service.find_by(id: state.parent_id)
          { type: work.model_name.human, title: Array(work.title).first }
        end
      rescue Valkyrie::Persistence::ObjectNotFoundError
        nil
      end

      # Drives whether the capability's review card renders expanded on load.
      def extra_prefilled?(kind)
        case kind
        when :parent     then state.parent_id.present?
        when :collection then selected_member_collections.any?
        when :sharing    then saved_permission_grants.any?
        when :redirects  then saved_redirect_paths.any?
        else false
        end
      end

      def eligible_parent_documents(query)
        search = Hyrax::SearchService.new(config: blacklight_config, user_params: { q: query.to_s },
                                          search_builder_class: Hyrax::My::FindWorksSearchBuilder,
                                          scope: context, current_ability: current_ability)
        _, docs = search.search_results do |builder|
          builder.with(q: query.to_s).with_access(:read).rows(20)
          types = eligible_parent_types
          builder.merge(fq: type_filter_query(types)) if types.present?
          builder
        end
        docs
      end

      def eligible_parent_types
        config.parent_types.presence || available_work_types.map(&:to_s)
      end

      def type_filter_query(type_names)
        clauses = Array(type_names).map { |name| "has_model_ssim:\"#{name}\"" }
        "(#{clauses.join(' OR ')})"
      end

      def last_deposited
        session.delete(:deposit_wizard_last)
      end

      # Active deposit-agreement mode requires the depositor to tick the checkbox
      # before committing; passive mode is informational only.
      def deposit_agreement_required?
        Flipflop.show_deposit_agreement? && Flipflop.active_deposit_agreement_acceptance?
      end

      # Messages from the last failed #deposit, for the controller to flash on the
      # re-rendered review step.
      attr_reader :commit_errors

      # Create the work, apply per-file embargo/lease, and run the configured
      # post-commit hook (e.g. Enact nesting). Returns the work, or nil on
      # validation/transaction failure (recorded in #commit_errors so the
      # re-rendered review step isn't silent).
      def deposit
        work = create_work
        return unless work

        apply_file_embargoes_and_leases(work)
        config.post_commit&.call(work, state)
        work
      end

      # e.g. invalid redirect path or video embed the form validator rejected.
      # Also used by the details step (Navigation) to explain a validation failure.
      def form_error_messages(form)
        form.errors.full_messages
      end

      private

      attr_reader :context

      # Run the stock CreateValkyrieWork action (same as the deposit form). Returns
      # the work, or nil on validation/transaction failure (recorded in
      # #commit_errors).
      def create_work
        @commit_errors = nil
        action = Hyrax::Action::CreateValkyrieWork.new(form: work_form,
                                                       transactions: Hyrax::Transactions::Container,
                                                       user: current_user,
                                                       params: commit_params,
                                                       work_attributes_key: work_form.model_name.param_key)
        return record_commit_failure(form_error_messages(action.form)) unless action.validate

        # Failure#or returns the block's value, so branch explicitly rather than
        # chaining .value_or (which would run on the block's nil result).
        result = action.perform
        return result.value! if result.success?

        record_commit_failure(transaction_failure_messages(result.failure))
      end

      def record_commit_failure(messages)
        @commit_errors = Array(messages)
        nil
      end

      # A transaction Failure's first element is a symbol reason (e.g.
      # :redirect_path_collision); prefer a translation for it, else its detail.
      def transaction_failure_messages(failure)
        reason, *detail = Array(failure)
        message = I18n.t("hyku.deposit_wizard.errors.commit.#{reason}", default: nil) ||
                  Array(detail).flatten.map(&:to_s).presence&.to_sentence || reason.to_s.humanize
        Array(message)
      end

      # The params CreateValkyrieWork expects, assembled from wizard state: the
      # work attributes (with the chosen admin set, and any per-file metadata
      # under +file_set+) under its param key, plus the uploaded-file ids.
      def commit_params
        attributes = state.attributes.merge('admin_set_id' => selected_admin_set_id).compact
        attributes['file_set'] = file_set_params if file_set_params.any?
        params = {
          work_form.model_name.param_key => attributes,
          'uploaded_files' => state.uploaded_file_ids
        }
        # parent_id is top-level (not under the work key); add_to_parent reads it there.
        params['parent_id'] = state.parent_id if state.parent_id.present?
        ActionController::Parameters.new(params)
      end

      # Per-file metadata for CreateValkyrieWork's add_file_sets step: one hash
      # per uploaded file, in attach order, carrying its uploaded_file_id (used to
      # match visibility) and entered fields. When a file inherits the work's
      # visibility, its visibility params are dropped so it follows the work.
      #
      # Keys are symbolized because WorkUploadsHandler#file_set_args merges this
      # into a symbol-keyed default hash; string keys would not override the
      # defaults, so entered metadata (title, description, ...) would be dropped.
      # The FileSet constructor ignores non-attribute keys (uploaded_file_id), and
      # visibility is applied separately by the handler.
      def file_set_params
        @file_set_params ||= state.uploaded_file_ids.map do |id|
          meta = state.file_metadata[id.to_s].to_h.dup
          meta['uploaded_file_id'] = id.to_s
          inherits = meta.delete('inherit_visibility') != '0'
          if inherits
            meta.reject! { |k, _| k.to_s.start_with?('visibility') || k.to_s.include?('embargo') || k.to_s.include?('lease') }
          else
            normalize_file_visibility!(meta)
          end
          meta.symbolize_keys
        end
      end

      # Apply each file's OWN embargo/lease after commit. add_file_sets copies the
      # work's embargo/lease onto every FileSet, so first clear the inherited one,
      # then apply the file's choice. FileSets are matched by identity, not array
      # position: find_members does not guarantee uploaded_file_ids order.
      def apply_file_embargoes_and_leases(work)
        file_set_ids = file_set_ids_by_uploaded_file
        file_sets = Hyrax.query_service.find_members(resource: work).index_by { |fs| fs.id.to_s }
        state.uploaded_file_ids.each do |id|
          meta = state.file_metadata[id.to_s].to_h
          next if meta['inherit_visibility'] != '0'
          file_set = file_sets[file_set_ids[id.to_s]]
          next if file_set.nil?

          clear_inherited_restrictions(file_set)
          case meta['visibility']
          when 'embargo' then apply_file_embargo(file_set, meta)
          when 'lease'   then apply_file_lease(file_set, meta)
          end
          saved = Hyrax.persister.save(resource: file_set)
          Hyrax.publisher.publish('object.metadata.updated', object: saved, user: current_user)
        end
      end

      # The visibility component submits "embargo"/"lease" as the visibility, but
      # those are selectors, not real visibilities: passing them to a FileSet's
      # `visibility=` raises UnknownVisibility. Replace the flat visibility with the
      # during-condition (what the file is *now*), and drop the embargo/lease detail
      # keys so they are not merged onto the FileSet as junk attributes. The actual
      # embargo/lease record is applied post-commit from state (see
      # #apply_file_embargoes_and_leases), which still has the untouched detail fields.
      def normalize_file_visibility!(meta)
        case meta['visibility']
        when 'embargo' then meta['visibility'] = meta['visibility_during_embargo']
        when 'lease'   then meta['visibility'] = meta['visibility_during_lease']
        end
        meta.reject! { |k, _| k.to_s.include?('embargo') || k.to_s.include?('lease') }
      end

      # Map each uploaded-file id to the id of the FileSet it was attached to.
      # WorkUploadsHandler records the link on the UploadedFile as file_set_uri
      # (via #add_file_set!); the FileSet id is its trailing path segment.
      def file_set_ids_by_uploaded_file
        Hyrax::UploadedFile.where(id: state.uploaded_file_ids).each_with_object({}) do |uf, map|
          map[uf.id.to_s] = uf.file_set_uri.to_s.split('/').last
        end
      end

      # Drop any embargo/lease the file inherited from the work (copied down by the
      # add_file_sets step) so the file's own choice starts from a clean slate. The
      # association is stored as embargo_id/lease_id, so detach by clearing the id
      # (assigning nil to the object accessor raises).
      def clear_inherited_restrictions(file_set)
        file_set.embargo_id = nil
        file_set.lease_id = nil
      end

      def apply_file_embargo(file_set, meta)
        file_set.embargo = Hyrax.persister.save(resource: Hyrax::Embargo.new(
          visibility_during_embargo: meta['visibility_during_embargo'],
          visibility_after_embargo: meta['visibility_after_embargo'],
          embargo_release_date: meta['embargo_release_date']
        ))
        Hyrax::EmbargoManager.apply_embargo_for(resource: file_set)
      end

      def apply_file_lease(file_set, meta)
        file_set.lease = Hyrax.persister.save(resource: Hyrax::Lease.new(
          visibility_during_lease: meta['visibility_during_lease'],
          visibility_after_lease: meta['visibility_after_lease'],
          lease_expiration_date: meta['lease_expiration_date']
        ))
        Hyrax::LeaseManager.apply_lease_for(resource: file_set)
      end
    end
  end
end
