# frozen_string_literal: true

module Hyrax
  module DepositWizard
    # Commit-side behavior: assembling the params CreateValkyrieWork expects from
    # wizard state, running the create action, and recording the result. Kept
    # separate from Context (the view/step/form helpers) for cohesion.
    module Persistence
      extend ActiveSupport::Concern

      # Active deposit-agreement mode requires the depositor to tick the checkbox
      # before committing; passive mode is informational only.
      def deposit_agreement_required?
        Flipflop.show_deposit_agreement? && Flipflop.active_deposit_agreement_acceptance?
      end

      def work_params
        params.fetch(wizard_state.work_type.constantize.model_name.param_key, {})
      end

      # Run the stock CreateValkyrieWork action (same as the deposit form) to
      # persist the work and attach the uploaded files. Returns the work, or nil
      # when validation or the transaction fails.
      def create_work
        action = Hyrax::Action::CreateValkyrieWork.new(form: work_form,
                                                       transactions: Hyrax::Transactions::Container,
                                                       user: current_user,
                                                       params: commit_params,
                                                       work_attributes_key: work_form.model_name.param_key)
        return unless action.validate

        action.perform.value_or(nil)
      end

      # Survive the redirect to the done screen, which reads it once. The show
      # path is built here where the work object is available.
      def stash_deposited(work)
        session[:deposit_wizard_last] = {
          'title' => Array(work.title).first,
          'path' => main_app.polymorphic_path([main_app, work])
        }
      end

      # The params CreateValkyrieWork expects, assembled from wizard state: the
      # work attributes (with the chosen admin set, and any per-file metadata
      # under +file_set+) under its param key, plus the uploaded-file ids.
      def commit_params
        attributes = wizard_state.attributes.merge('admin_set_id' => selected_admin_set_id).compact
        attributes['file_set'] = file_set_params if file_set_params.any?
        ActionController::Parameters.new(
          work_form.model_name.param_key => attributes,
          'uploaded_files' => wizard_state.uploaded_file_ids
        )
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
        @file_set_params ||= wizard_state.uploaded_file_ids.map do |id|
          meta = wizard_state.file_metadata[id.to_s].to_h.dup
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

      # The visibility component submits "embargo"/"lease" as the visibility, but
      # those are selectors, not real visibilities: passing them to a FileSet's
      # `visibility=` raises UnknownVisibility. Replace the flat visibility with the
      # during-condition (what the file is *now*), and drop the embargo/lease detail
      # keys so they are not merged onto the FileSet as junk attributes. The actual
      # embargo/lease record is applied post-commit from wizard_state (see the
      # controller), which still has the untouched detail fields.
      def normalize_file_visibility!(meta)
        case meta['visibility']
        when 'embargo' then meta['visibility'] = meta['visibility_during_embargo']
        when 'lease'   then meta['visibility'] = meta['visibility_during_lease']
        end
        meta.reject! { |k, _| k.to_s.include?('embargo') || k.to_s.include?('lease') }
      end

      # Apply per-file embargo/lease after the work and FileSets are saved.
      # WorkUploadsHandler only assigns a flat visibility, and add_file_sets copies
      # the *work's* embargo/lease onto every FileSet. So for a file with its OWN
      # visibility we must first clear any inherited embargo/lease (else a file
      # leased under an embargoed work keeps both) before applying its own choice.
      # Inheriting files are left with whatever add_file_sets copied down.
      def apply_file_embargoes_and_leases(work)
        file_set_ids = file_set_ids_by_uploaded_file
        file_sets = Hyrax.query_service.find_members(resource: work).index_by { |fs| fs.id.to_s }
        wizard_state.uploaded_file_ids.each do |id|
          meta = wizard_state.file_metadata[id.to_s].to_h
          next if meta['inherit_visibility'] != '0'
          file_set = file_sets[file_set_ids[id.to_s]]
          next if file_set.nil?

          clear_inherited_restrictions(file_set)
          case meta['visibility']
          when 'embargo' then apply_file_embargo(file_set, meta)
          when 'lease'   then apply_file_lease(file_set, meta)
          end
          Hyrax.persister.save(resource: file_set)
        end
      end

      # Map each uploaded-file id to the id of the FileSet it was attached to.
      # WorkUploadsHandler records the link on the UploadedFile as file_set_uri
      # (via #add_file_set!); the FileSet id is its trailing path segment.
      def file_set_ids_by_uploaded_file
        Hyrax::UploadedFile.where(id: wizard_state.uploaded_file_ids).each_with_object({}) do |uf, map|
          map[uf.id.to_s] = uf.file_set_uri.to_s.split('/').last
        end
      end

      # Drop any embargo/lease the file inherited from the work (copied down by the
      # add_file_sets step) so the file's own choice starts from a clean slate. The
      # association is stored as embargo_id/lease_id, so detach by clearing the id
      # (assigning nil to the object accessor raises). The file's flat visibility
      # was already set by the handler.
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
