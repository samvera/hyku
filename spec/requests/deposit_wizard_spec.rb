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
    end
  end

  describe 'GET /deposit_wizard/:step with an unknown step' do
    before { allow(Flipflop).to receive(:deposit_wizard?).and_return(true) }

    it 'falls back to the start screen' do
      get deposit_wizard_step_path(step: 'does_not_exist')

      expect(response).to redirect_to(deposit_wizard_path)
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

    context 'with a container config' do
      before do
        Hyku::DepositWizard.config = Hyku::DepositWizard::Config.new { |c| c.container_type = 'GenericWorkResource' }
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

    describe 'the inline admin-set choice' do
      it 'records an admin set submitted with the start choice' do
        admin_set_id = Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id.to_s
        patch deposit_wizard_advance_path(step: 'start'),
              params: { work_type: work_type, admin_set_id: admin_set_id }

        expect(session[:deposit_wizard]['admin_set_id']).to eq(admin_set_id)
      end
    end

    describe 'the files step' do
      it 'redirects back to type selection when no work type has been chosen' do
        get deposit_wizard_step_path(step: 'files')

        expect(response).to redirect_to(deposit_wizard_step_path(step: 'known_type'))
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
        expect(response.body).to include('administrative set')
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
        patch deposit_wizard_advance_path(step: 'start'), params: { work_type: work_type }
        patch deposit_wizard_advance_path(step: 'details'),
              params: { param_key => { title: ['Embargoed'], creator: ['Ada'],
                                       visibility: 'embargo',
                                       visibility_during_embargo: 'restricted',
                                       embargo_release_date: '2099-01-01',
                                       visibility_after_embargo: 'open' } }
        get deposit_wizard_step_path(step: 'review')

        expect(response.body).to include('2099-01-01')
        expect(response.body).to match(/Embargo:.*until 2099-01-01, then/)
      end

      it 'summarizes a lease as a transitional phrase, not a bare badge' do
        patch deposit_wizard_advance_path(step: 'start'), params: { work_type: work_type }
        patch deposit_wizard_advance_path(step: 'details'),
              params: { param_key => { title: ['Leased'], creator: ['Ada'],
                                       visibility: 'lease',
                                       visibility_during_lease: 'open',
                                       lease_expiration_date: '2099-01-01',
                                       visibility_after_lease: 'restricted' } }
        get deposit_wizard_step_path(step: 'review')

        expect(response.body).to include('2099-01-01')
        expect(response.body).to match(/Lease:.*until 2099-01-01, then/)
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
        upload = FactoryBot.create(:uploaded_file, user: admin)
        patch deposit_wizard_advance_path(step: 'start'), params: { work_type: work_type }
        patch deposit_wizard_advance_path(step: 'files'), params: { uploaded_files: [upload.id.to_s] }
        patch deposit_wizard_advance_path(step: 'details'),
              params: { param_key => { title: ['Embargoed work'], creator: ['Ada'],
                                       visibility: 'embargo',
                                       visibility_during_embargo: 'restricted',
                                       embargo_release_date: '2099-01-01',
                                       visibility_after_embargo: 'open' } }
        # File gets its OWN embargo, different release date than the work.
        patch deposit_wizard_advance_path(step: 'file_meta'),
              params: { file_metadata: { upload.id.to_s =>
                { inherit_visibility: '0', visibility: 'embargo',
                  visibility_during_embargo: 'restricted',
                  embargo_release_date: '2088-06-06',
                  visibility_after_embargo: 'open' } } }

        resource_class = Hyrax::ModelRegistry.work_classes
                                             .detect { |k| k < Hyrax::Resource && k.model_name.param_key == param_key }
        expect { post deposit_wizard_commit_path }.not_to raise_error
        expect(response).to redirect_to(deposit_wizard_step_path(step: 'done'))

        work = Hyrax.query_service.find_all_of_model(model: resource_class).to_a.last
        file_set = Hyrax.query_service.find_members(resource: work).to_a.first
        expect(file_set.embargo&.embargo_release_date&.to_date&.iso8601).to eq('2088-06-06')
        expect(file_set.visibility).to eq('restricted')
      end

      it 'gives the file only its own lease when the work is embargoed' do
        upload = FactoryBot.create(:uploaded_file, user: admin)
        patch deposit_wizard_advance_path(step: 'start'), params: { work_type: work_type }
        patch deposit_wizard_advance_path(step: 'files'), params: { uploaded_files: [upload.id.to_s] }
        patch deposit_wizard_advance_path(step: 'details'),
              params: { param_key => { title: ['Embargoed work'], creator: ['Ada'],
                                       visibility: 'embargo',
                                       visibility_during_embargo: 'restricted',
                                       embargo_release_date: '2099-01-01',
                                       visibility_after_embargo: 'open' } }
        patch deposit_wizard_advance_path(step: 'file_meta'),
              params: { file_metadata: { upload.id.to_s =>
                { inherit_visibility: '0', visibility: 'lease',
                  visibility_during_lease: 'open',
                  lease_expiration_date: '2088-06-06',
                  visibility_after_lease: 'restricted' } } }

        resource_class = Hyrax::ModelRegistry.work_classes
                                             .detect { |k| k < Hyrax::Resource && k.model_name.param_key == param_key }
        post deposit_wizard_commit_path

        work = Hyrax.query_service.find_all_of_model(model: resource_class).to_a.last
        file_set = Hyrax.query_service.find_members(resource: work).to_a.first
        # The file should carry ITS lease and NOT the work's inherited embargo.
        expect(file_set.lease&.lease_expiration_date&.to_date&.iso8601).to eq('2088-06-06')
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
                                       lease_expiration_date: '2099-01-01',
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
