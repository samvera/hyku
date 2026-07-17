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

      # The work types the type chooser offers. Defaults to everything the user is
      # authorized to deposit; a downstream app narrows this to config.item_types
      # (intersected with authorization, so it can restrict but never widen it).
      def available_work_types
        authorized = Hyrax::QuickClassificationQuery.new(current_user).authorized_models
        return authorized if config.item_types.blank?

        allowed = Array(config.item_types).map(&:to_s)
        authorized.select { |model| allowed.include?(model.to_s) }
      end

      # The stepper rail rows ({n:, label:, icon:}) for the current state, built
      # from the flow's rail (one entry per distinct visible rail_key).
      def item_stepper_steps
        stepper_rail.each_with_index.map do |row, i|
          { n: i + 1, label: I18n.t("hyku.deposit_wizard.stepper.item.#{row[:label_key]}"), icon: row[:icon] }
        end
      end

      # The zero-based index of the rail entry for +rail_key+ (the key each step
      # view passes for its own position), or -1 to hide the rail.
      def stepper_phase(rail_key)
        stepper_rail.index { |row| row[:key] == rail_key.to_sym } || -1
      end

      def stepper_rail
        config.flow.rail(state, config)
      end

      attr_reader :work_form, :latest_schema_version

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

      # Basic (non-compound) work fields with a value, as {label:, value:} rows for
      # the review summary. schema_version/contexts are bookkeeping, not shown.
      def review_basic_terms
        terms = (work_form.primary_terms + work_form.secondary_terms) - %i[schema_version contexts]
        terms.filter_map do |term|
          value = review_term_value(term)
          { label: review_term_label(term), value: value.join(', ') } if value.present?
        end
      end

      # Compound fields with entries, as {label:, count:} rows (the review shows a
      # count rather than expanding each nested entry).
      def review_compound_terms
        work_form.compound_terms.filter_map do |term|
          entries = review_term_value(term)
          { label: review_term_label(term), count: entries.size } if entries.present?
        end
      end

      def file_type_label(uploaded_file)
        ext = File.extname(uploaded_file.file&.file&.filename.to_s).delete('.').upcase
        ext.presence || I18n.t('hyku.deposit_wizard.file_meta.file')
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

      # The current selection and embargo/lease prefill values to render for +form+
      # (the work form, or a per-file FileSet form), so navigating Back restores them.
      def visibility_fields(form)
        embargo = form.object.try(:embargo)
        lease   = form.object.try(:lease)
        tomorrow = Time.zone.today + 1 # a valid future default for the date fields
        VisibilityFields.new(
          current: current_visibility(form, embargo, lease),
          embargo_date: embargo&.embargo_release_date&.to_date || tomorrow,
          embargo_during: embargo&.visibility_during_embargo,
          embargo_after: embargo&.visibility_after_embargo,
          lease_date: lease&.lease_expiration_date&.to_date || tomorrow,
          lease_during: lease&.visibility_during_lease,
          lease_after: lease&.visibility_after_lease
        )
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

      def available_admin_sets
        @available_admin_sets ||=
          Hyrax::AdminSetSelectionPresenter.new(admin_sets: admin_sets_for_deposit).select_options
      end

      def admin_sets_for_deposit
        Hyrax::AdminSetService.new(context).search_results(:deposit)
      end

      # Keep the presenter's data-* hash on each option: the visibility component
      # enforces those visibility/release rules downstream on the details form. The
      # description/workflow prose is built by AdminSetDescription.
      def admin_set_options_for_display
        @admin_set_options_for_display ||= begin
          docs = admin_sets_for_deposit
          templates = Hyrax::PermissionTemplate.where(source_id: docs.map { |d| d.id.to_s }).to_a
          docs.map do |doc|
            template = templates.find { |t| t.source_id == doc.id.to_s }
            entry = Hyrax::AdminSetSelectionPresenter::OptionsEntry.new(admin_set: doc, permission_template: template)
            label, id, data = entry.result
            guidance = AdminSetDescription.new(admin_set: doc, permission_template: template)
            { id: id, label: label, data: data,
              description: guidance.summary, workflow: guidance.workflow_label }
          end
        end
      end

      def multiple_admin_sets?
        admin_set_options_for_display.size > 1
      end

      # The VisibilityPolicy for the selected admin set, built from its
      # permission-template data-* (see VisibilityPolicy for the rules).
      def visibility_policy
        selected = admin_set_options_for_display.find { |o| o[:id].to_s == selected_admin_set_id.to_s }
        VisibilityPolicy.from_admin_set_data(selected&.dig(:data) || {})
      end

      # Name the chosen admin set on review only when the depositor actually had a
      # choice (more than one set) and a name resolved.
      def show_review_destination?
        multiple_admin_sets? && selected_admin_set_name.present?
      end

      def show_relationship_paths?
        config.container? || config.parent_connect_on_start?
      end

      # Flow questions delegate to the configured step map (see
      # Hyku::DepositWizard::Flow), so ordering/skips/prerequisites live in one
      # place. `next_step`/`back_step` compute forward/back targets for the current
      # state; `step_detour` sends an unrenderable step elsewhere.
      def valid_step?(step)
        config.flow.valid_step?(step)
      end

      def step_detour(step)
        config.flow.detour_for(step, state, config)
      end

      def next_step(step)
        config.flow.next_after(step, state, config)
      end

      def back_step(step)
        config.flow.back_before(step, state, config)
      end

      # Record the choice submitted on +step+ into wizard state and return the
      # Transition (advance or re-render) the controller should apply. The wizard
      # is server-rendered: each step is a GET, its choice POSTs here.
      def advance_from(step)
        case step
        when 'start'         then advance_from_start
        when 'select_parent' then advance_from_select_parent
        when 'item_start'    then Transition.advance(next_step('item_start'))
        when 'known_type'    then select_work_type
        when 'files'         then advance_from_files
        when 'details'       then advance_from_details
        when 'file_meta'     then advance_from_file_meta
        end
      end

      def work_params
        params.fetch(state.work_type.constantize.model_name.param_key, {})
      end

      # Copy the enabled connect/share/redirect capabilities posted with the
      # deposit form into wizard state before commit.
      def capture_review_extras
        keys = enabled_extra_attribute_keys
        if keys.any?
          posted = params.fetch(work_form.model_name.param_key, {}).permit!.to_h
          attributes = state.attributes
          # Delete-when-absent (not merge) so removing all of a capability's
          # entries clears it rather than leaving the prior value to reappear.
          keys.each { |key| posted.key?(key) ? attributes[key] = posted[key] : attributes.delete(key) }
          state.attributes = attributes
        end

        # Guard on params.key? so an absent parent_id doesn't clobber one seeded at
        # launch (the handoff) or on the start "add" path.
        return unless config.parent_connect_on_review? && params.key?(:parent_id)
        state.parent_id = params[:parent_id]
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
      # post-commit hook (e.g. downstream nesting). Returns the work, or nil on
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
      def form_error_messages(form)
        form.errors.full_messages
      end

      private

      attr_reader :context

      def review_term_value(term)
        return unless work_form.respond_to?(term)

        Array(work_form.send(term)).reject(&:blank?)
      end

      # Which visibility option to pre-select. When an embargo/lease is active the
      # flat `visibility` holds the *during* value (not "embargo"/"lease"), so the
      # sub-form's presence is what selects it; otherwise use `visibility`, defaulting
      # to Private.
      def current_visibility(form, embargo, lease)
        if embargo&.embargo_release_date.present?
          Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO
        elsif lease&.lease_expiration_date.present?
          Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE
        else
          form.object.try(:visibility).presence || Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        end
      end

      def review_term_label(term)
        I18n.t(term, scope: 'simple_form.labels.defaults', default: term.to_s.humanize)
      end

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

      def advance_from_start
        state.admin_set_id = params[:admin_set_id] if params.key?(:admin_set_id)

        # The flat (non-relationship) start screen chooses the work type inline, so
        # a posted path is only honored when the path cards are actually offered.
        unless params.key?(:path) && show_relationship_paths?
          state.path = 'standalone'
          return select_work_type(rerender_step: 'start')
        end

        state.path = params[:path]
        Transition.advance(next_step('start'))
      end

      def advance_from_select_parent
        return rerender_parent_required if params[:parent_id].blank?

        state.parent_id = params[:parent_id]
        Transition.advance(next_step('select_parent'))
      end

      def rerender_parent_required
        Transition.rerender('select_parent', alert: 'hyku.deposit_wizard.errors.no_parent')
      end

      def select_work_type(rerender_step: 'known_type')
        type = params[:work_type].to_s
        return rerender_bad_work_type(rerender_step) unless available_work_types.map(&:to_s).include?(type)

        state.work_type = type
        Transition.advance(next_step('known_type'),
                           notice: I18n.t('hyku.deposit_wizard.notices.work_type_selected',
                                          type: type.constantize.model_name.human))
      end

      def rerender_bad_work_type(step)
        Transition.rerender(step, alert: 'hyku.deposit_wizard.errors.no_work_type')
      end

      def advance_from_files
        # `uploaded_files[]` is emitted by Hyrax's upload js_templates for each
        # completed upload, matching the param name stock deposit uses.
        state.uploaded_file_ids = params[:uploaded_files]
        state.primary_file_id = params[:primary_file_id]
        Transition.advance(next_step('files'))
      end

      # The ChangeSet permits its own fields, so raw nested params go straight to
      # #validate, as the stock works controller does. The submitted values (plain
      # strings/arrays) are stored so they serialize into the session.
      def advance_from_details
        build_work_form
        unless work_form.validate(work_params)
          return Transition.rerender('details', alert: 'hyku.deposit_wizard.errors.details_invalid',
                                                messages: form_error_messages(work_form))
        end

        state.attributes = work_params.to_unsafe_h
        Transition.advance(next_step('details'))
      end

      def advance_from_file_meta
        submitted = params.fetch(:file_metadata, {}).permit!.to_h
        allowed = state.uploaded_file_ids.map(&:to_s)
        state.file_metadata = submitted.slice(*allowed)
        Transition.advance(next_step('file_meta'))
      end

      def enabled_extra_attribute_keys
        keys = []
        keys << 'member_of_collections_attributes' if config.capabilities.collection_connect?
        keys << 'permissions_attributes' if config.capabilities.sharing?
        keys.push('redirects_attributes', 'redirects_display_url_index') if config.redirects_available?
        keys
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
