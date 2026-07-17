# frozen_string_literal: true

RSpec.describe 'Deposit wizard', type: :request, singletenant: true, clean: true do
  let(:admin) { FactoryBot.create(:admin) }

  before do
    FactoryBot.create(:admin_group)
    FactoryBot.create(:registered_group)
    login_as admin
  end

  describe 'GET /deposit_wizard' do
    context 'when the deposit_wizard feature is off' do
      before { allow(Flipflop).to receive(:deposit_wizard?).and_return(false) }

      it 'redirects to the dashboard with an alert and does not expose the wizard' do
        get deposit_wizard_path

        expect(response).to redirect_to(hyrax.my_works_path)
        expect(flash[:alert]).to eq(I18n.t('hyku.deposit_wizard.disabled'))
      end
    end

    context 'when the deposit_wizard feature is on' do
      before { allow(Flipflop).to receive(:deposit_wizard?).and_return(true) }

      it 'renders the start screen' do
        get deposit_wizard_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include(I18n.t('hyku.deposit_wizard.page_heading'))
      end

      it 'renders the dashboard breadcrumb trail' do
        get deposit_wizard_path

        expect(response.body).to include(I18n.t('hyrax.controls.home'))
        expect(response.body).to include(I18n.t('hyku.deposit_wizard.button'))
      end

      describe 'launch with context (handoff from another entry point)' do
        after { Hyku::DepositWizard.reset_config! }

        it 'seeds a parent work from parent_id when parent connect is enabled' do
          allow(Flipflop).to receive(:deposit_wizard_parent_connect?).and_return(true)
          get deposit_wizard_path(parent_id: 'parent-123')

          expect(session[:deposit_wizard]['parent_id']).to eq('parent-123')
        end

        it 'ignores parent_id when parent connect is disabled' do
          allow(Flipflop).to receive(:deposit_wizard_parent_connect?).and_return(false)
          get deposit_wizard_path(parent_id: 'parent-123')

          expect(session[:deposit_wizard]['parent_id']).to be_nil
        end

        it 'seeds collection membership from add_works_to_collection when enabled' do
          allow(Flipflop).to receive(:deposit_wizard_collection_connect?).and_return(true)
          get deposit_wizard_path(add_works_to_collection: 'coll-9')

          membership = session[:deposit_wizard].dig('attributes', 'member_of_collections_attributes')
          expect(membership).to be_present
          expect(membership.values.map { |row| row['id'] }).to include('coll-9')
        end

        it 'ignores add_works_to_collection when collection connect is disabled' do
          allow(Flipflop).to receive(:deposit_wizard_collection_connect?).and_return(false)
          get deposit_wizard_path(add_works_to_collection: 'coll-9')

          expect(session[:deposit_wizard].dig('attributes', 'member_of_collections_attributes')).to be_blank
        end
      end
    end
  end

  describe 'GET /deposit_wizard/:step with an unknown step' do
    before { allow(Flipflop).to receive(:deposit_wizard?).and_return(true) }

    it 'falls back to the start screen' do
      get deposit_wizard_step_path(step: 'does_not_exist')

      expect(response).to redirect_to(deposit_wizard_path)
    end
  end

  describe 'GET /deposit_wizard/parent_options (parent typeahead)' do
    let(:admin) { FactoryBot.create(:admin) }

    before do
      allow(Flipflop).to receive(:deposit_wizard?).and_return(true)
      allow(Flipflop).to receive(:deposit_wizard_parent_connect?).and_return(true)
    end

    after { Hyku::DepositWizard.reset_config! }

    it 'returns matching works as JSON id/label pairs' do
      parent = FactoryBot.valkyrie_create(:generic_work_resource, title: ['Findable Parent'],
                                                                  depositor: admin.user_key,
                                                                  visibility_setting: 'open')

      get deposit_wizard_parent_options_path(q: 'Findable')

      expect(response).to have_http_status(:success)
      results = JSON.parse(response.body)
      expect(results).to be_an(Array)
      expect(results.map { |r| r['id'] }).to include(parent.id.to_s)
    end

    it 'is forbidden when parent connect is disabled' do
      allow(Flipflop).to receive(:deposit_wizard_parent_connect?).and_return(false)

      get deposit_wizard_parent_options_path(q: 'anything')

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'navigation and type selection' do
    before do
      allow(Flipflop).to receive(:deposit_wizard?).and_return(true)
      Hyrax::AdminSetCreateService.find_or_create_default_admin_set
    end

    # A work type the wizard offers (same list as the stock deposit chooser).
    let(:work_type) do
      Hyrax::QuickClassificationQuery.new(admin).authorized_models.first.to_s
    end

    # The param key is shared by the ActiveFedora model and its Valkyrie form.
    let(:param_key) { work_type.constantize.model_name.param_key }

    after { Hyku::DepositWizard.reset_config! }

    context 'with a flat config (no container)' do
      before { Hyku::DepositWizard.reset_config! }

      it 'renders a work-type chooser on the start screen' do
        get deposit_wizard_path

        expect(response.body).to include(I18n.t('hyku.deposit_wizard.known_type.heading'))
      end

      it 'shows an empty-state message when no work types are available' do
        allow_any_instance_of(Hyrax::QuickClassificationQuery).to receive(:authorized_models).and_return([])

        get deposit_wizard_path

        expect(response.body).to include(I18n.t('hyku.deposit_wizard.no_work_types'))
      end

      it 'persists the chosen work type and advances to the files step' do
        patch deposit_wizard_advance_path(step: 'start'), params: { work_type: work_type }

        expect(response).to redirect_to(deposit_wizard_step_path(step: 'files'))
        expect(session[:deposit_wizard]['work_type']).to eq(work_type)
        expect(session[:deposit_wizard]['path']).to eq('standalone')
      end

      it 're-renders with an alert when the work type is not allowed' do
        patch deposit_wizard_advance_path(step: 'start'), params: { work_type: 'NotAWorkType' }

        expect(response).to have_http_status(:success)
        expect(response.body).to include(I18n.t('hyku.deposit_wizard.errors.no_work_type'))
        expect(session[:deposit_wizard]['work_type']).to be_nil
      end
    end

    context 'with a container config offering a sub-flow' do
      before do
        Hyku::DepositWizard.config = Hyku::DepositWizard::Config.new do |c|
          c.container_type = 'GenericWorkResource'
          c.suggestions = { image: %w[GenericWorkResource] }
        end
      end

      it 'renders the path chooser on the start screen' do
        get deposit_wizard_path

        expect(response.body).to include(I18n.t('hyku.deposit_wizard.start.paths.new.title'))
        expect(response.body).to include(I18n.t('hyku.deposit_wizard.start.paths.standalone.title'))
      end

      it 'records the chosen path and advances to item_start' do
        patch deposit_wizard_advance_path(step: 'start'), params: { path: 'standalone' }

        expect(response).to redirect_to(deposit_wizard_step_path(step: 'item_start'))
        expect(session[:deposit_wizard]['path']).to eq('standalone')
      end

      it 'advances item_start to the type chooser' do
        patch deposit_wizard_advance_path(step: 'item_start')

        expect(response).to redirect_to(deposit_wizard_step_path(step: 'known_type'))
      end

      it 'persists the chosen work type on known_type' do
        patch deposit_wizard_advance_path(step: 'known_type'), params: { work_type: work_type }

        expect(session[:deposit_wizard]['work_type']).to eq(work_type)
      end
    end

    context 'with a container config offering no sub-flow' do
      before do
        Hyku::DepositWizard.config = Hyku::DepositWizard::Config.new { |c| c.container_type = 'GenericWorkResource' }
      end

      it 'skips item_start and goes straight to the type chooser' do
        patch deposit_wizard_advance_path(step: 'start'), params: { path: 'standalone' }

        expect(response).to redirect_to(deposit_wizard_step_path(step: 'known_type'))
      end

      it 'redirects a direct item_start visit to the type chooser' do
        get deposit_wizard_step_path(step: 'item_start')

        expect(response).to redirect_to(deposit_wizard_step_path(step: 'known_type'))
      end
    end

    context 'with the relationship-first path (flat config, parent_connect on)' do
      before do
        allow(Flipflop).to receive(:deposit_wizard_parent_connect?).and_return(true)
        # These exercise the start-screen path; the default placement is review-only.
        Hyku::DepositWizard.config.parent_connect_placement = :both
      end

      after { Hyku::DepositWizard.reset_config! }

      it 'renders the new/add path cards on the start screen' do
        get deposit_wizard_path

        expect(response.body).to include(I18n.t('hyku.deposit_wizard.start.paths.new.title'))
        expect(response.body).to include(I18n.t('hyku.deposit_wizard.start.paths.add.title'))
      end

      it 'sends the add path to the select_parent step' do
        patch deposit_wizard_advance_path(step: 'start'), params: { path: 'add' }

        expect(response).to redirect_to(deposit_wizard_step_path(step: 'select_parent'))
        expect(session[:deposit_wizard]['path']).to eq('add')
      end

      it 'sends the new path to type selection' do
        patch deposit_wizard_advance_path(step: 'start'), params: { path: 'new' }

        expect(response).to redirect_to(deposit_wizard_step_path(step: 'known_type'))
      end

      it 'seeds the chosen parent and advances from select_parent' do
        parent = FactoryBot.valkyrie_create(:generic_work_resource, title: ['Parent'], depositor: admin.user_key)
        patch deposit_wizard_advance_path(step: 'start'), params: { path: 'add' }

        patch deposit_wizard_advance_path(step: 'select_parent'), params: { parent_id: parent.id.to_s }

        expect(response).to redirect_to(deposit_wizard_step_path(step: 'known_type'))
        expect(session[:deposit_wizard]['parent_id']).to eq(parent.id.to_s)
      end

      it 're-renders select_parent with an alert when no parent is chosen' do
        patch deposit_wizard_advance_path(step: 'start'), params: { path: 'add' }

        patch deposit_wizard_advance_path(step: 'select_parent'), params: { parent_id: '' }

        expect(response).to have_http_status(:success)
        expect(response.body).to include(I18n.t('hyku.deposit_wizard.errors.no_parent'))
        expect(session[:deposit_wizard]['parent_id']).to be_nil
      end

      it 'redirects select_parent to start when the add path is not active' do
        get deposit_wizard_step_path(step: 'select_parent')

        expect(response).to redirect_to(deposit_wizard_path)
      end

      it 'shows the chosen parent and a Back-to-parent link on the type chooser' do
        parent = FactoryBot.valkyrie_create(:generic_work_resource, title: ['Umbrella'], depositor: admin.user_key)
        patch deposit_wizard_advance_path(step: 'start'), params: { path: 'add' }
        patch deposit_wizard_advance_path(step: 'select_parent'), params: { parent_id: parent.id.to_s }

        get deposit_wizard_step_path(step: 'known_type')

        expect(response.body).to include(I18n.t('hyku.deposit_wizard.known_type.adding_to'))
        expect(response.body).to include('Umbrella')
        expect(response.body).to include('Generic Work') # the parent's model name
        expect(response.body).to include(deposit_wizard_step_path(step: 'select_parent'))
      end
    end

    context 'with parent-connect placement :review (review edge only)' do
      before do
        allow(Flipflop).to receive(:deposit_wizard_parent_connect?).and_return(true)
        Hyku::DepositWizard.config.parent_connect_placement = :review
      end

      after { Hyku::DepositWizard.reset_config! }

      it 'shows the flat type chooser and no add path card on the start screen' do
        get deposit_wizard_path

        expect(response.body).to include(I18n.t('hyku.deposit_wizard.known_type.heading'))
        expect(response.body).not_to include(I18n.t('hyku.deposit_wizard.start.paths.add.title'))
      end

      it 'redirects the add path away since it is not offered up front' do
        patch deposit_wizard_advance_path(step: 'start'), params: { path: 'add' }

        expect(response).not_to redirect_to(deposit_wizard_step_path(step: 'select_parent'))
      end
    end

    context 'with the relationship-first path off' do
      it 'shows the flat type chooser and no path cards' do
        get deposit_wizard_path

        expect(response.body).to include(I18n.t('hyku.deposit_wizard.known_type.heading'))
        expect(response.body).not_to include(I18n.t('hyku.deposit_wizard.start.paths.add.title'))
      end
    end

    describe 'the inline admin-set choice' do
      it 'records an admin set submitted with the start choice' do
        admin_set_id = Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id.to_s
        patch deposit_wizard_advance_path(step: 'start'),
              params: { work_type: work_type, admin_set_id: admin_set_id }

        expect(session[:deposit_wizard]['admin_set_id']).to eq(admin_set_id)
      end
    end

    describe 'the files step' do
      it 'renders without a work type (upload has no prerequisite)' do
        get deposit_wizard_step_path(step: 'files')

        expect(response).to have_http_status(:success)
        expect(response.body).to include(I18n.t('hyku.deposit_wizard.files.heading'))
      end

      context 'after a work type is chosen' do
        before { patch deposit_wizard_advance_path(step: 'start'), params: { work_type: work_type } }

        it 'renders the files step with the uploader' do
          get deposit_wizard_step_path(step: 'files')

          expect(response).to have_http_status(:success)
          expect(response.body).to include('fileupload-deposit-wizard')
          expect(response.body).to include(I18n.t('hyku.deposit_wizard.files.heading'))
        end

        it 'stores uploaded file ids and the primary selection, then advances to details' do
          patch deposit_wizard_advance_path(step: 'files'),
                params: { uploaded_files: %w[3 7], primary_file_id: '7' }

          expect(session[:deposit_wizard]['uploaded_file_ids']).to eq(%w[3 7])
          expect(session[:deposit_wizard]['primary_file_id']).to eq('7')
          expect(response).to redirect_to(deposit_wizard_step_path(step: 'details'))
        end
      end
    end

    describe 'the details step' do
      it 'redirects back to type selection when no work type has been chosen' do
        get deposit_wizard_step_path(step: 'details')

        expect(response).to redirect_to(deposit_wizard_step_path(step: 'known_type'))
      end

      context 'after a work type is chosen' do
        before { patch deposit_wizard_advance_path(step: 'start'), params: { work_type: work_type } }

        it 'renders the metadata form and the visibility component' do
          get deposit_wizard_step_path(step: 'details')

          expect(response).to have_http_status(:success)
          expect(response.body).to include(I18n.t('hyku.deposit_wizard.details.heading'))
          expect(response.body).to include("#{param_key}[title]")
          expect(response.body).to include("#{param_key}[visibility]")
        end

        it 'still renders the metadata fields after files -> back -> forward' do
          upload = FactoryBot.create(:uploaded_file, user: admin)
          patch deposit_wizard_advance_path(step: 'files'), params: { uploaded_files: [upload.id.to_s] }
          get deposit_wizard_step_path(step: 'details')
          expect(response.body).to include("#{param_key}[title]")

          # Back to files, then forward to details again.
          get deposit_wizard_step_path(step: 'files')
          patch deposit_wizard_advance_path(step: 'files'), params: { uploaded_files: [upload.id.to_s] }
          get deposit_wizard_step_path(step: 'details')

          expect(response).to have_http_status(:success)
          expect(response.body).to include("#{param_key}[title]")
          expect(response.body).to include("#{param_key}[creator]")
        end

        it 'persists valid metadata and advances' do
          patch deposit_wizard_advance_path(step: 'details'),
                params: { param_key => { title: ['A guided deposit work'], creator: ['Ada Lovelace'] } }

          expect(session[:deposit_wizard]['attributes']['title']).to eq(['A guided deposit work'])
          expect(response).to redirect_to(deposit_wizard_step_path(step: 'review'))
        end

        it 're-renders details with an error when a server-only field fails' do
          patch deposit_wizard_advance_path(step: 'details'),
                params: { param_key => { title: ['Bad embed'], creator: ['Ada'],
                                         video_embed: 'not a url' } }

          expect(response).to have_http_status(:success)
          expect(response).not_to redirect_to(deposit_wizard_step_path(step: 'review'))
          expect(response.body).to include(I18n.t('hyku.deposit_wizard.errors.details_invalid'))
          # The submission is not advanced into wizard state on failure.
          expect(session[:deposit_wizard]['attributes']).to be_blank
          # Entered values survive the re-render so the depositor can correct them.
          expect(response.body).to include('Bad embed')
          expect(response.body).to include('not a url')
        end

        it 're-renders details with an embargo work visibility restored (Back)' do
          patch deposit_wizard_advance_path(step: 'details'),
                params: { param_key => { title: ['Embargoed'], creator: ['Ada'],
                                         visibility: 'embargo',
                                         visibility_during_embargo: 'restricted',
                                         embargo_release_date: 30.days.from_now.to_date.iso8601,
                                         visibility_after_embargo: 'open' } }

          get deposit_wizard_step_path(step: 'details')

          expect(response).to have_http_status(:success)
          expect(response.body).to include("#{param_key}[visibility_during_embargo]")
        end

        it 're-renders the form when required metadata is missing' do
          patch deposit_wizard_advance_path(step: 'details'),
                params: { param_key => { title: [''] } }

          expect(response).to have_http_status(:success)
          expect(session[:deposit_wizard]['attributes']).to be_nil
        end
      end
    end

    describe 'the per-file metadata step' do
      before { patch deposit_wizard_advance_path(step: 'start'), params: { work_type: work_type } }

      it 'skips file_meta and lands on review when no files were uploaded' do
        get deposit_wizard_step_path(step: 'file_meta')

        expect(response).to redirect_to(deposit_wizard_step_path(step: 'review'))
      end

      it 'advancing details goes straight to review when there are no files' do
        patch deposit_wizard_advance_path(step: 'details'),
              params: { param_key => { title: ['No files here'], creator: ['Ada'] } }

        expect(response).to redirect_to(deposit_wizard_step_path(step: 'review'))
      end

      context 'with uploaded files' do
        let(:upload) { FactoryBot.create(:uploaded_file, user: admin) }

        before { patch deposit_wizard_advance_path(step: 'files'), params: { uploaded_files: [upload.id.to_s] } }

        it 'advancing details goes to file_meta when files exist' do
          patch deposit_wizard_advance_path(step: 'details'),
                params: { param_key => { title: ['Has a file'], creator: ['Ada'] } }

          expect(response).to redirect_to(deposit_wizard_step_path(step: 'file_meta'))
        end

        it 'renders a panel per uploaded file with a visibility choice' do
          get deposit_wizard_step_path(step: 'file_meta')

          expect(response).to have_http_status(:success)
          expect(response.body).to include("file_metadata[#{upload.id}][title]")
          expect(response.body).to include("file_metadata[#{upload.id}][visibility]")
        end

        it 'renders a hidden inherit_visibility companion so unchecking submits a value' do
          get deposit_wizard_step_path(step: 'file_meta')

          # A bare checkbox submits nothing when unchecked; the hidden field ensures
          # an explicit "0" (own visibility) is sent, so it is not misread as inherit.
          expect(response.body).to include(%(<input type="hidden" name="file_metadata[#{upload.id}][inherit_visibility]" value="0"))
        end

        it 'persists per-file metadata and advances to review' do
          patch deposit_wizard_advance_path(step: 'file_meta'),
                params: { file_metadata: { upload.id.to_s => { title: 'Cover image', visibility: 'inherit' } } }

          expect(session[:deposit_wizard]['file_metadata'][upload.id.to_s]['title']).to eq('Cover image')
          expect(response).to redirect_to(deposit_wizard_step_path(step: 'review'))
        end

        it 'drops metadata keyed to files not in the current wizard state' do
          other_upload = FactoryBot.create(:uploaded_file, user: admin)
          patch deposit_wizard_advance_path(step: 'file_meta'),
                params: { file_metadata: {
                  upload.id.to_s => { title: 'Mine' },
                  other_upload.id.to_s => { title: 'Not in this wizard run' }
                } }

          stored = session[:deposit_wizard]['file_metadata']
          expect(stored.keys).to contain_exactly(upload.id.to_s)
          expect(stored).not_to have_key(other_upload.id.to_s)
        end

        it 'restores entered per-file metadata when returning to the step' do
          patch deposit_wizard_advance_path(step: 'file_meta'),
                params: { file_metadata: { upload.id.to_s => { title: ['Cover image'] } } }
          # Return to the file_meta step (e.g. Back from review).
          get deposit_wizard_step_path(step: 'file_meta')

          expect(response).to have_http_status(:success)
          expect(response.body).to include('Cover image')
        end
      end
    end

    describe 'review and commit' do
      before do
        Hyrax::AdminSetCreateService.find_or_create_default_admin_set
        # Pin the deposit-agreement flags off by default so commit isn't gated;
        # the active-acceptance context turns them on explicitly.
        allow(Flipflop).to receive(:show_deposit_agreement?).and_return(false)
        allow(Flipflop).to receive(:active_deposit_agreement_acceptance?).and_return(false)
      end

      # Walk to a valid review state: choose a type (the admin set defaults),
      # then submit required metadata.
      def fill_in_wizard
        patch deposit_wizard_advance_path(step: 'start'), params: { work_type: work_type }
        patch deposit_wizard_advance_path(step: 'details'),
              params: { param_key => { title: ['Repair Study'], creator: ['Ada Lovelace'] } }
      end

      it 'renders a summary including visibility on the review step' do
        fill_in_wizard
        get deposit_wizard_step_path(step: 'review')

        expect(response).to have_http_status(:success)
        expect(response.body).to include(I18n.t('hyku.deposit_wizard.review.heading'))
        expect(response.body).to include('Repair Study')
        expect(response.body).to include(I18n.t('hyku.deposit_wizard.review.work_visibility'))
      end

      describe 'autosaving review extras (survive a refresh)' do
        after { Hyku::DepositWizard.reset_config! }

        it 'saves a chosen parent into wizard state and re-renders it on review' do
          allow(Flipflop).to receive(:deposit_wizard_parent_connect?).and_return(true)
          parent = FactoryBot.valkyrie_create(:generic_work_resource, title: ['Parent'], depositor: admin.user_key)
          fill_in_wizard

          post deposit_wizard_extras_path, params: { parent_id: parent.id.to_s }
          expect(response).to have_http_status(:no_content)
          expect(session[:deposit_wizard]['parent_id']).to eq(parent.id.to_s)

          get deposit_wizard_step_path(step: 'review')
          expect(response.body).to include(parent.id.to_s)
        end

        it 'saves collection membership into wizard state' do
          allow(Flipflop).to receive(:deposit_wizard_collection_connect?).and_return(true)
          collection = FactoryBot.create(:hyku_collection, user: admin)
          fill_in_wizard

          post deposit_wizard_extras_path,
               params: { param_key => { member_of_collections_attributes: { '0' => { id: collection.id.to_s } } } }

          expect(response).to have_http_status(:no_content)
          captured = session[:deposit_wizard].dig('attributes', 'member_of_collections_attributes')
          expect(captured&.dig('0', 'id')).to eq(collection.id.to_s)
        end

        it 'clears a capability from state when its entries are removed' do
          allow(Flipflop).to receive(:deposit_wizard_collection_connect?).and_return(true)
          collection = FactoryBot.create(:hyku_collection, user: admin)
          fill_in_wizard

          post deposit_wizard_extras_path,
               params: { param_key => { member_of_collections_attributes: { '0' => { id: collection.id.to_s } } } }
          expect(session[:deposit_wizard].dig('attributes', 'member_of_collections_attributes')).to be_present

          post deposit_wizard_extras_path, params: { param_key => { title: ['x'] } }
          expect(session[:deposit_wizard].dig('attributes', 'member_of_collections_attributes')).to be_blank
        end

        it 'rejects the save before a work type is chosen' do
          post deposit_wizard_extras_path, params: { parent_id: 'x' }
          expect(response).to have_http_status(:bad_request)
        end
      end

      describe 'the parent connect section on review' do
        after { Hyku::DepositWizard.reset_config! }

        it 'renders the section when parent connect is enabled' do
          allow(Flipflop).to receive(:deposit_wizard_parent_connect?).and_return(true)
          fill_in_wizard
          get deposit_wizard_step_path(step: 'review')

          expect(response.body).to include('data-behavior="extra-parent"')
          expect(response.body).to include(I18n.t('hyku.deposit_wizard.extras.parent.heading'))
        end

        it 'omits the section when parent connect is disabled' do
          allow(Flipflop).to receive(:deposit_wizard_parent_connect?).and_return(false)
          fill_in_wizard
          get deposit_wizard_step_path(step: 'review')

          expect(response.body).not_to include('data-behavior="extra-parent"')
        end

        it 'omits the section when placement is :start (front edge only)' do
          allow(Flipflop).to receive(:deposit_wizard_parent_connect?).and_return(true)
          Hyku::DepositWizard.config.parent_connect_placement = :start
          fill_in_wizard
          get deposit_wizard_step_path(step: 'review')

          expect(response.body).not_to include('data-behavior="extra-parent"')
        end

        it 'renders the section when placement is :review' do
          allow(Flipflop).to receive(:deposit_wizard_parent_connect?).and_return(true)
          Hyku::DepositWizard.config.parent_connect_placement = :review
          fill_in_wizard
          get deposit_wizard_step_path(step: 'review')

          expect(response.body).to include('data-behavior="extra-parent"')
        end
      end

      describe 'the collection connect section on review' do
        after { Hyku::DepositWizard.reset_config! }

        it 'renders the section when the capability is enabled' do
          allow(Flipflop).to receive(:deposit_wizard_collection_connect?).and_return(true)
          fill_in_wizard
          get deposit_wizard_step_path(step: 'review')

          expect(response.body).to include('data-behavior="extra-collection"')
          expect(response.body).to include(I18n.t('hyku.deposit_wizard.extras.collection.heading'))
        end

        it 'omits the section when the capability is disabled' do
          allow(Flipflop).to receive(:deposit_wizard_collection_connect?).and_return(false)
          fill_in_wizard
          get deposit_wizard_step_path(step: 'review')

          expect(response.body).not_to include('data-behavior="extra-collection"')
        end
      end

      describe 'the sharing section on review' do
        after { Hyku::DepositWizard.reset_config! }

        it 'renders the section when sharing is enabled' do
          allow(Flipflop).to receive(:deposit_wizard_sharing?).and_return(true)
          fill_in_wizard
          get deposit_wizard_step_path(step: 'review')

          expect(response.body).to include('data-behavior="extra-sharing"')
          expect(response.body).to include(I18n.t('hyku.deposit_wizard.extras.sharing.heading'))
        end

        it 'omits the section when sharing is disabled' do
          allow(Flipflop).to receive(:deposit_wizard_sharing?).and_return(false)
          fill_in_wizard
          get deposit_wizard_step_path(step: 'review')

          expect(response.body).not_to include('data-behavior="extra-sharing"')
        end
      end

      describe 'the redirects section on review' do
        it 'renders the section when redirects are active and the work carries the attribute' do
          allow(Hyrax.config).to receive(:redirects_active?).and_return(true)
          allow_any_instance_of(Hyku::DepositWizard::Config)
            .to receive(:redirects_available?).and_return(true)
          fill_in_wizard
          get deposit_wizard_step_path(step: 'review')

          expect(response.body).to include('data-behavior="extra-redirects"')
          expect(response.body).to include(I18n.t('hyku.deposit_wizard.extras.redirects.heading'))
        end

        it 'omits the section when redirects are not active' do
          allow(Hyrax.config).to receive(:redirects_active?).and_return(false)
          fill_in_wizard
          get deposit_wizard_step_path(step: 'review')

          expect(response.body).not_to include('data-behavior="extra-redirects"')
        end

        it 'omits the section when the work does not carry the redirects attribute' do
          allow(Hyrax.config).to receive(:redirects_active?).and_return(true)
          allow_any_instance_of(Hyku::DepositWizard::Config)
            .to receive(:redirects_available?).and_return(false)
          fill_in_wizard
          get deposit_wizard_step_path(step: 'review')

          expect(response.body).not_to include('data-behavior="extra-redirects"')
        end
      end

      it 'review Back goes to file_meta when there are files, else details' do
        # No files: Back -> details.
        fill_in_wizard
        get deposit_wizard_step_path(step: 'review')
        expect(response.body).to include(deposit_wizard_step_path(step: 'details'))
        expect(response.body).not_to include(deposit_wizard_step_path(step: 'file_meta'))

        # With a file: Back -> file_meta.
        upload = FactoryBot.create(:uploaded_file, user: admin)
        patch deposit_wizard_advance_path(step: 'files'), params: { uploaded_files: [upload.id.to_s] }
        get deposit_wizard_step_path(step: 'review')
        expect(response.body).to include(deposit_wizard_step_path(step: 'file_meta'))
      end

      it 'still shows the work fields on review after going back to details and forward' do
        fill_in_wizard
        get deposit_wizard_step_path(step: 'review')
        expect(response.body).to include('Repair Study')

        # Back to details (a GET), then forward again by re-submitting details.
        get deposit_wizard_step_path(step: 'details')
        patch deposit_wizard_advance_path(step: 'details'),
              params: { param_key => { title: ['Repair Study'], creator: ['Ada Lovelace'] } }
        get deposit_wizard_step_path(step: 'review')

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Repair Study')
        expect(response.body).to include('Ada Lovelace')
      end

      it 'summarizes an embargo as a transitional phrase, not a bare badge' do
        release_date = 30.days.from_now.to_date.iso8601
        patch deposit_wizard_advance_path(step: 'start'), params: { work_type: work_type }
        patch deposit_wizard_advance_path(step: 'details'),
              params: { param_key => { title: ['Embargoed'], creator: ['Ada'],
                                       visibility: 'embargo',
                                       visibility_during_embargo: 'restricted',
                                       embargo_release_date: release_date,
                                       visibility_after_embargo: 'open' } }
        get deposit_wizard_step_path(step: 'review')

        expect(response.body).to include(release_date)
        expect(response.body).to match(/Embargo:.*until #{release_date}, then/)
      end

      it 'summarizes a lease as a transitional phrase, not a bare badge' do
        expiration_date = 30.days.from_now.to_date.iso8601
        patch deposit_wizard_advance_path(step: 'start'), params: { work_type: work_type }
        patch deposit_wizard_advance_path(step: 'details'),
              params: { param_key => { title: ['Leased'], creator: ['Ada'],
                                       visibility: 'lease',
                                       visibility_during_lease: 'open',
                                       lease_expiration_date: expiration_date,
                                       visibility_after_lease: 'restricted' } }
        get deposit_wizard_step_path(step: 'review')

        expect(response.body).to include(expiration_date)
        expect(response.body).to match(/Lease:.*until #{expiration_date}, then/)
      end

      context 'when the deposit agreement is in active-acceptance mode' do
        before do
          allow(Flipflop).to receive(:show_deposit_agreement?).and_return(true)
          allow(Flipflop).to receive(:active_deposit_agreement_acceptance?).and_return(true)
        end

        it 'blocks the commit until the agreement is accepted' do
          fill_in_wizard

          post deposit_wizard_commit_path

          expect(response).to have_http_status(:success)
          expect(response.body).to include(I18n.t('hyku.deposit_wizard.errors.agreement_required'))
          expect(response).not_to redirect_to(deposit_wizard_step_path(step: 'done'))
        end

        it 'commits when the agreement checkbox is accepted' do
          fill_in_wizard

          post deposit_wizard_commit_path, params: { agreement: '1' }

          expect(response).to redirect_to(deposit_wizard_step_path(step: 'done'))
        end
      end

      context 'when the deposit fails server-side validation' do
        it 'stays on review and shows why when the form is invalid' do
          # Stub the form-validation failure at the action seam (like the
          # transaction-failure sibling below). Driving it through a real invalid
          # field made the outcome depend on the ambient flexible schema/feature
          # state, which other specs mutate — an order-dependent failure. This
          # asserts the error-surfacing behavior itself, deterministically.
          allow_any_instance_of(Hyrax::Action::CreateValkyrieWork)
            .to receive(:validate).and_return(false)
          fill_in_wizard

          post deposit_wizard_commit_path

          expect(response).to have_http_status(:success)
          expect(response).not_to redirect_to(deposit_wizard_step_path(step: 'done'))
          expect(response.body).to include(I18n.t('hyku.deposit_wizard.errors.deposit_failed'))
        end

        it 'shows a friendly message for a commit-only transaction failure' do
          # A redirect-path collision is only detectable at commit; the create
          # transaction returns Failure([:redirect_path_collision, ...]).
          allow_any_instance_of(Hyrax::Action::CreateValkyrieWork)
            .to receive(:validate).and_return(true)
          allow_any_instance_of(Hyrax::Action::CreateValkyrieWork)
            .to receive(:perform).and_return(Dry::Monads::Failure([:redirect_path_collision, 'taken']))
          fill_in_wizard

          post deposit_wizard_commit_path

          expect(response).to have_http_status(:success)
          expect(response).not_to redirect_to(deposit_wizard_step_path(step: 'done'))
          expect(response.body).to include(I18n.t('hyku.deposit_wizard.errors.commit.redirect_path_collision'))
        end
      end

      it 'commits the work and lands on the done screen' do
        fill_in_wizard
        resource_class = Hyrax::ModelRegistry.work_classes
                                             .detect { |k| k < Hyrax::Resource && k.model_name.param_key == param_key }

        expect { post deposit_wizard_commit_path }
          .to change { Hyrax.query_service.find_all_of_model(model: resource_class).count }.by(1)

        expect(response).to redirect_to(deposit_wizard_step_path(step: 'done'))
        expect(session[:deposit_wizard]).to eq({})
      end

      it 'applies a per-file embargo that differs from the work embargo' do
        work_date = 30.days.from_now.to_date
        file_date = 60.days.from_now.to_date
        upload = FactoryBot.create(:uploaded_file, user: admin)
        patch deposit_wizard_advance_path(step: 'start'), params: { work_type: work_type }
        patch deposit_wizard_advance_path(step: 'files'), params: { uploaded_files: [upload.id.to_s] }
        patch deposit_wizard_advance_path(step: 'details'),
              params: { param_key => { title: ['Embargoed work'], creator: ['Ada'],
                                       visibility: 'embargo',
                                       visibility_during_embargo: 'restricted',
                                       embargo_release_date: work_date.iso8601,
                                       visibility_after_embargo: 'open' } }
        # File gets its OWN embargo, different release date than the work.
        patch deposit_wizard_advance_path(step: 'file_meta'),
              params: { file_metadata: { upload.id.to_s =>
                { inherit_visibility: '0', visibility: 'embargo',
                  visibility_during_embargo: 'restricted',
                  embargo_release_date: file_date.iso8601,
                  visibility_after_embargo: 'open' } } }

        resource_class = Hyrax::ModelRegistry.work_classes
                                             .detect { |k| k < Hyrax::Resource && k.model_name.param_key == param_key }
        expect { post deposit_wizard_commit_path }.not_to raise_error
        expect(response).to redirect_to(deposit_wizard_step_path(step: 'done'))

        work = Hyrax.query_service.find_all_of_model(model: resource_class).to_a.last
        file_set = Hyrax.query_service.find_members(resource: work).to_a.first
        expect(file_set.embargo&.embargo_release_date&.to_date).to eq(file_date)
        expect(file_set.visibility).to eq('restricted')
      end

      it 'gives the file only its own lease when the work is embargoed' do
        work_date = 30.days.from_now.to_date
        file_date = 60.days.from_now.to_date
        upload = FactoryBot.create(:uploaded_file, user: admin)
        patch deposit_wizard_advance_path(step: 'start'), params: { work_type: work_type }
        patch deposit_wizard_advance_path(step: 'files'), params: { uploaded_files: [upload.id.to_s] }
        patch deposit_wizard_advance_path(step: 'details'),
              params: { param_key => { title: ['Embargoed work'], creator: ['Ada'],
                                       visibility: 'embargo',
                                       visibility_during_embargo: 'restricted',
                                       embargo_release_date: work_date.iso8601,
                                       visibility_after_embargo: 'open' } }
        patch deposit_wizard_advance_path(step: 'file_meta'),
              params: { file_metadata: { upload.id.to_s =>
                { inherit_visibility: '0', visibility: 'lease',
                  visibility_during_lease: 'open',
                  lease_expiration_date: file_date.iso8601,
                  visibility_after_lease: 'restricted' } } }

        resource_class = Hyrax::ModelRegistry.work_classes
                                             .detect { |k| k < Hyrax::Resource && k.model_name.param_key == param_key }
        post deposit_wizard_commit_path

        work = Hyrax.query_service.find_all_of_model(model: resource_class).to_a.last
        file_set = Hyrax.query_service.find_members(resource: work).to_a.first
        # The file should carry ITS lease and NOT the work's inherited embargo.
        expect(file_set.lease&.lease_expiration_date&.to_date).to eq(file_date)
        expect(file_set.embargo&.embargo_release_date).to be_blank
      end

      it 'commits a work under lease with an inheriting file without error' do
        upload = FactoryBot.create(:uploaded_file, user: admin)
        patch deposit_wizard_advance_path(step: 'start'), params: { work_type: work_type }
        patch deposit_wizard_advance_path(step: 'files'), params: { uploaded_files: [upload.id.to_s] }
        patch deposit_wizard_advance_path(step: 'details'),
              params: { param_key => { title: ['Leased'], creator: ['Ada'],
                                       visibility: 'lease',
                                       visibility_during_lease: 'open',
                                       lease_expiration_date: 30.days.from_now.to_date.iso8601,
                                       visibility_after_lease: 'restricted' } }
        # file inherits (no per-file visibility submitted beyond the hidden inherit flag)
        patch deposit_wizard_advance_path(step: 'file_meta'),
              params: { file_metadata: { upload.id.to_s => { inherit_visibility: '1' } } }

        expect { post deposit_wizard_commit_path }.not_to raise_error
        expect(response).to redirect_to(deposit_wizard_step_path(step: 'done'))
      end

      it 'applies a per-file visibility that differs from the work' do
        upload = FactoryBot.create(:uploaded_file, user: admin)
        # Walk the wizard with a file, the work set open, and the file set private.
        patch deposit_wizard_advance_path(step: 'start'), params: { work_type: work_type }
        patch deposit_wizard_advance_path(step: 'files'), params: { uploaded_files: [upload.id.to_s] }
        patch deposit_wizard_advance_path(step: 'details'),
              params: { param_key => { title: ['Repair Study'], creator: ['Ada Lovelace'], visibility: 'open' } }
        # An unchecked "same as work" checkbox submits inherit_visibility=0 via the
        # hidden companion field, exactly as the browser does. Also enter per-file
        # metadata to confirm it lands on the FileSet (not just visibility).
        patch deposit_wizard_advance_path(step: 'file_meta'),
              params: { file_metadata: { upload.id.to_s =>
                { inherit_visibility: '0', visibility: 'restricted',
                  title: ['Cover image'], description: ['The front cover'] } } }

        resource_class = Hyrax::ModelRegistry.work_classes
                                             .detect { |k| k < Hyrax::Resource && k.model_name.param_key == param_key }
        post deposit_wizard_commit_path

        work = Hyrax.query_service.find_all_of_model(model: resource_class).to_a.last
        file_set = Hyrax.query_service.find_members(resource: work).to_a.first
        expect(work.visibility).to eq('open')
        expect(file_set.visibility).to eq('restricted')
        expect(file_set.title).to contain_exactly('Cover image')
        expect(file_set.description).to contain_exactly('The front cover')
      end

      it 'applies each file its own visibility when two files differ' do
        release_date = 30.days.from_now.to_date
        private_upload = FactoryBot.create(:uploaded_file, user: admin)
        embargo_upload = FactoryBot.create(:uploaded_file, user: admin)
        patch deposit_wizard_advance_path(step: 'start'), params: { work_type: work_type }
        patch deposit_wizard_advance_path(step: 'files'),
              params: { uploaded_files: [private_upload.id.to_s, embargo_upload.id.to_s] }
        patch deposit_wizard_advance_path(step: 'details'),
              params: { param_key => { title: ['Two file work'], creator: ['Ada'], visibility: 'open' } }
        # One file private, the other embargoed. Titled so each FileSet is
        # identifiable regardless of the order find_members returns them.
        patch deposit_wizard_advance_path(step: 'file_meta'),
              params: { file_metadata: {
                private_upload.id.to_s => { inherit_visibility: '0', visibility: 'restricted', title: ['Private one'] },
                embargo_upload.id.to_s => { inherit_visibility: '0', visibility: 'embargo', title: ['Embargo one'],
                                            visibility_during_embargo: 'restricted',
                                            embargo_release_date: release_date.iso8601,
                                            visibility_after_embargo: 'open' }
              } }

        resource_class = Hyrax::ModelRegistry.work_classes
                                             .detect { |k| k < Hyrax::Resource && k.model_name.param_key == param_key }

        # find_members does not guarantee it returns file sets in uploaded_file_ids
        # order. Force reversed order to prove the embargo is matched to the right
        # file by identity, not by array position.
        original = Hyrax.query_service.method(:find_members)
        allow(Hyrax.query_service).to receive(:find_members) do |**kwargs|
          result = original.call(**kwargs)
          result.respond_to?(:to_a) ? result.to_a.reverse : result
        end

        post deposit_wizard_commit_path

        work = Hyrax.query_service.find_all_of_model(model: resource_class).to_a.last
        file_sets = Hyrax.query_service.find_members(resource: work).to_a
        private_fs = file_sets.find { |fs| fs.title.include?('Private one') }
        embargo_fs = file_sets.find { |fs| fs.title.include?('Embargo one') }

        expect(work.visibility).to eq('open')
        expect(private_fs.visibility).to eq('restricted')
        expect(private_fs.embargo&.embargo_release_date).to be_blank
        expect(embargo_fs.embargo&.embargo_release_date&.to_date).to eq(release_date)
      end

      it "indexes a file's own lease when the work is leased with a different date" do
        work_date = 30.days.from_now.to_date
        file_date = 60.days.from_now.to_date
        upload = FactoryBot.create(:uploaded_file, user: admin)

        patch deposit_wizard_advance_path(step: 'start'), params: { work_type: work_type }
        patch deposit_wizard_advance_path(step: 'files'), params: { uploaded_files: [upload.id.to_s] }
        patch deposit_wizard_advance_path(step: 'details'),
              params: { param_key => { title: ['Leased work'], creator: ['Ada'],
                                       visibility: 'lease',
                                       visibility_during_lease: 'open',
                                       lease_expiration_date: work_date.iso8601,
                                       visibility_after_lease: 'restricted' } }
        patch deposit_wizard_advance_path(step: 'file_meta'),
              params: { file_metadata: {
                upload.id.to_s => { inherit_visibility: '0', visibility: 'lease', title: ['Own lease'],
                                    visibility_during_lease: 'open',
                                    lease_expiration_date: file_date.iso8601,
                                    visibility_after_lease: 'restricted' }
              } }

        resource_class = Hyrax::ModelRegistry.work_classes
                                             .detect { |k| k < Hyrax::Resource && k.model_name.param_key == param_key }
        post deposit_wizard_commit_path

        work = Hyrax.query_service.find_all_of_model(model: resource_class).to_a.last
        file_set = Hyrax.query_service.find_members(resource: work).to_a.first

        expect(file_set.lease&.lease_expiration_date&.to_date).to eq(file_date)
        expect(SolrDocument.find(file_set.id.to_s)['lease_expiration_date_dtsi']).to include(file_date.iso8601)
      end

      it 'runs the configured post-commit hook with the persisted work' do
        captured = []
        Hyku::DepositWizard.config.post_commit = ->(work, _state) { captured << work }
        fill_in_wizard

        post deposit_wizard_commit_path

        expect(captured.size).to eq(1)
        expect(captured.first).to be_present
      ensure
        Hyku::DepositWizard.reset_config!
      end

      it 'redirects to type selection when committing without a work type' do
        post deposit_wizard_commit_path

        expect(response).to redirect_to(deposit_wizard_step_path(step: 'known_type'))
      end

      describe 'the optional connect capabilities on the deposit (Review) form' do
        let(:resource_class) do
          Hyrax::ModelRegistry.work_classes.detect { |k| k < Hyrax::Resource && k.model_name.param_key == param_key }
        end

        after { Hyku::DepositWizard.reset_config! }

        context 'collection connect' do
          before { allow(Flipflop).to receive(:deposit_wizard_collection_connect?).and_return(true) }

          it 'adds the work to the chosen collection' do
            collection = FactoryBot.create(:hyku_collection, user: admin)
            fill_in_wizard

            post deposit_wizard_commit_path,
                 params: { param_key => { member_of_collections_attributes: { '0' => { id: collection.id.to_s } } } }

            expect(response).to redirect_to(deposit_wizard_step_path(step: 'done'))
            work = Hyrax.query_service.find_all_of_model(model: resource_class).to_a.last
            expect(work.member_of_collection_ids.map(&:to_s)).to include(collection.id.to_s)
          end
        end

        context 'when collection connect is disabled' do
          before { allow(Flipflop).to receive(:deposit_wizard_collection_connect?).and_return(false) }

          it 'ignores submitted collection membership' do
            collection = FactoryBot.create(:hyku_collection, user: admin)
            fill_in_wizard

            post deposit_wizard_commit_path,
                 params: { param_key => { member_of_collections_attributes: { '0' => { id: collection.id.to_s } } } }

            work = Hyrax.query_service.find_all_of_model(model: resource_class).to_a.last
            expect(work.member_of_collection_ids).to be_empty
          end
        end

        context 'parent connect' do
          before { allow(Flipflop).to receive(:deposit_wizard_parent_connect?).and_return(true) }

          it 'nests the work under the chosen parent work' do
            parent = FactoryBot.valkyrie_create(:generic_work_resource, title: ['Parent work'], depositor: admin.user_key)
            fill_in_wizard

            post deposit_wizard_commit_path, params: { parent_id: parent.id.to_s }

            expect(response).to redirect_to(deposit_wizard_step_path(step: 'done'))
            reloaded_parent = Hyrax.query_service.find_by(id: parent.id)
            child = Hyrax.query_service.find_all_of_model(model: resource_class).to_a
                         .reject { |w| w.id.to_s == parent.id.to_s }.last
            expect(reloaded_parent.member_ids.map(&:to_s)).to include(child.id.to_s)
          end

          it 'nests using a parent seeded at launch (handoff), without re-posting it' do
            parent = FactoryBot.valkyrie_create(:generic_work_resource, title: ['Parent work'], depositor: admin.user_key)
            # Launch the wizard from the parent's "attach child" action.
            get deposit_wizard_path(parent_id: parent.id.to_s)
            fill_in_wizard

            post deposit_wizard_commit_path

            reloaded_parent = Hyrax.query_service.find_by(id: parent.id)
            child = Hyrax.query_service.find_all_of_model(model: resource_class).to_a
                         .reject { |w| w.id.to_s == parent.id.to_s }.last
            expect(reloaded_parent.member_ids.map(&:to_s)).to include(child.id.to_s)
          end
        end

        context 'when parent connect is disabled' do
          before { allow(Flipflop).to receive(:deposit_wizard_parent_connect?).and_return(false) }

          it 'ignores a submitted parent_id' do
            parent = FactoryBot.valkyrie_create(:generic_work_resource, title: ['Parent work'], depositor: admin.user_key)
            fill_in_wizard

            post deposit_wizard_commit_path, params: { parent_id: parent.id.to_s }

            reloaded_parent = Hyrax.query_service.find_by(id: parent.id)
            expect(reloaded_parent.member_ids).to be_empty
          end
        end

        context 'sharing' do
          before { allow(Flipflop).to receive(:deposit_wizard_sharing?).and_return(true) }

          it 'grants a user the access chosen on the review step' do
            grantee = FactoryBot.create(:user)
            fill_in_wizard

            post deposit_wizard_commit_path,
                 params: { param_key => { permissions_attributes: {
                   '0' => { type: 'person', name: grantee.user_key, access: 'edit' }
                 } } }

            expect(response).to redirect_to(deposit_wizard_step_path(step: 'done'))
            work = Hyrax.query_service.find_all_of_model(model: resource_class).to_a.last
            expect(work.permission_manager.edit_users.to_a).to include(grantee.user_key)
          end
        end

        context 'when sharing is disabled' do
          before { allow(Flipflop).to receive(:deposit_wizard_sharing?).and_return(false) }

          it 'ignores submitted permissions' do
            grantee = FactoryBot.create(:user)
            fill_in_wizard

            post deposit_wizard_commit_path,
                 params: { param_key => { permissions_attributes: {
                   '0' => { type: 'person', name: grantee.user_key, access: 'edit' }
                 } } }

            work = Hyrax.query_service.find_all_of_model(model: resource_class).to_a.last
            expect(work.permission_manager.edit_users.to_a).not_to include(grantee.user_key)
          end
        end

        # The wizard's job for redirects is to CAPTURE the submitted params into
        # the work attributes when the capability is available; the actual
        # persistence is Hyrax's redirects populator + sync_redirect_paths step,
        # which fire only when the `redirects` attribute is in the active schema
        # (an env/profile concern, not a wizard concern). These specs assert the
        # wizard's capture behavior, gated by the capability. reset_state is
        # stubbed so the captured session is observable after commit.
        context 'redirects' do
          before do
            allow(Hyrax.config).to receive(:redirects_active?).and_return(true)
            allow_any_instance_of(Hyrax::DepositWizardController).to receive(:reset_state)
          end

          it 'captures the submitted vanity URL into the work attributes' do
            fill_in_wizard

            post deposit_wizard_commit_path,
                 params: { param_key => { redirects_attributes: { '0' => { path: '/my-vanity-url' } } } }

            expect(response).to redirect_to(deposit_wizard_step_path(step: 'done'))
            captured = session[:deposit_wizard].dig('attributes', 'redirects_attributes')
            expect(captured&.dig('0', 'path')).to eq('/my-vanity-url')
          end
        end

        context 'when redirects are not active' do
          before do
            allow(Hyrax.config).to receive(:redirects_active?).and_return(false)
            allow_any_instance_of(Hyrax::DepositWizardController).to receive(:reset_state)
          end

          it 'ignores a submitted redirect path' do
            fill_in_wizard

            post deposit_wizard_commit_path,
                 params: { param_key => { redirects_attributes: { '0' => { path: '/my-vanity-url' } } } }

            expect(session[:deposit_wizard].dig('attributes', 'redirects_attributes')).to be_blank
          end
        end
      end
    end
  end

  describe 'the Guided Deposit button on the works page' do
    # A default admin set grants the admin work-create ability, which the button
    # (like the stock "Add new work" button) is gated on.
    before { Hyrax::AdminSetCreateService.find_or_create_default_admin_set }

    it 'appears when the feature is on' do
      allow(Flipflop).to receive(:deposit_wizard?).and_return(true)

      get hyrax.my_works_path

      expect(response.body).to include('guided-deposit-button')
      expect(response.body).to include(I18n.t('hyku.deposit_wizard.button'))
    end

    it 'is absent when the feature is off' do
      allow(Flipflop).to receive(:deposit_wizard?).and_return(false)

      get hyrax.my_works_path

      expect(response.body).not_to include('guided-deposit-button')
    end
  end
end
