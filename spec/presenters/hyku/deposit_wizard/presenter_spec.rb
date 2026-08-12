# frozen_string_literal: true

RSpec.describe Hyku::DepositWizard::Presenter do
  subject(:presenter) { described_class.new(context) }

  # Stands in for the controller the presenter delegates request primitives to.
  let(:context) do
    double(session: session, current_user: nil, current_ability: nil,
           params: params, main_app: nil, blacklight_config: nil)
  end
  let(:session) { {} }
  let(:params) { ActionController::Parameters.new }

  after { Hyku::DepositWizard.reset_config! }

  describe '#config' do
    it 'returns the shared wizard config' do
      expect(presenter.config).to be(Hyku::DepositWizard.config)
    end
  end

  describe '#state' do
    it 'wraps the session-backed wizard state' do
      expect(presenter.state).to be_a(Hyku::DepositWizard::State)
    end

    it 'memoizes a single state instance' do
      expect(presenter.state).to be(presenter.state)
    end
  end

  describe '#step_detour' do
    it 'sends a work-type-requiring step back to known_type when no type is chosen' do
      expect(presenter.step_detour('details')).to eq('known_type')
    end

    it 'skips file_meta to review when nothing was uploaded' do
      presenter.state.work_type = 'GenericWork'
      expect(presenter.step_detour('file_meta')).to eq('review')
    end

    it 'sends select_parent back to start when the add path is not active' do
      presenter.state.work_type = 'GenericWork'
      expect(presenter.step_detour('select_parent')).to eq('start')
    end

    it 'renders a valid step (no detour)' do
      presenter.state.work_type = 'GenericWork'
      expect(presenter.step_detour('details')).to be_nil
    end
  end

  describe '#advance_from' do
    let(:params) { ActionController::Parameters.new(step: 'select_parent') }

    it 're-renders select_parent with an alert when no parent was chosen' do
      transition = presenter.advance_from('select_parent')
      expect(transition).not_to be_advance
      expect(transition.step).to eq('select_parent')
      expect(transition.alert).to eq('hyku.deposit_wizard.errors.no_parent')
    end

    context 'when a parent is chosen' do
      let(:user) { FactoryBot.create(:user) }
      let(:parent) { FactoryBot.valkyrie_create(:generic_work_resource, edit_users: [user]) }
      let(:params) { ActionController::Parameters.new(step: 'select_parent', parent_id: parent.id.to_s) }
      let(:context) do
        double(session: session, current_user: user, current_ability: Ability.new(user),
               params: params, main_app: nil, blacklight_config: nil)
      end

      it 'stores the parent and advances' do
        transition = presenter.advance_from('select_parent')
        expect(transition).to be_advance
        expect(presenter.state.parent_id).to eq(parent.id.to_s)
      end
    end

    context 'when the chosen parent cannot contain children' do
      let(:params) { ActionController::Parameters.new(step: 'select_parent', parent_id: 'abc123') }

      it 're-renders select_parent and leaves the parent unset' do
        transition = presenter.advance_from('select_parent')
        expect(transition).not_to be_advance
        expect(transition.alert).to eq('hyku.deposit_wizard.errors.parent_not_allowed')
        expect(presenter.state.parent_id).to be_nil
      end
    end

    context 'with a step the presenter does not explicitly handle' do
      # A downstream app can insert its own steps into the flow; the presenter
      # falls back to advancing to the next visible step (a decorator overrides
      # this only for steps that need custom side-effects).
      it 'advances to the next visible step' do
        allow(presenter.config.flow).to receive(:next_after).with('inserted', anything, anything).and_return('files')
        transition = presenter.advance_from('inserted')
        expect(transition).to be_advance
        expect(transition.step).to eq('files')
      end
    end
  end

  describe '#advance_from (details step)' do
    let(:params) do
      ActionController::Parameters.new(step: 'details',
                                       'generic_work' => { 'title' => ['A title'] })
    end
    let(:work_form) { instance_double(Hyrax::Forms::ResourceForm) }

    before do
      presenter.state.work_type = 'GenericWorkResource'
      allow(presenter).to receive(:build_work_form).and_return(work_form)
      allow(presenter).to receive(:work_form).and_return(work_form)
      allow(work_form).to receive(:validate).and_return(true)
      allow(presenter.config.flow).to receive(:next_after).and_return('review')
    end

    it 'preserves a launch-seeded collection through the details step' do
      presenter.state.attributes = { 'member_of_collections_attributes' => { '0' => { 'id' => 'coll-7' } } }

      presenter.advance_from('details')

      seeded = presenter.state.attributes['member_of_collections_attributes']
      expect(seeded).to be_present
      expect(seeded.values.map { |row| row['id'] }).to include('coll-7')
      expect(presenter.state.attributes['title']).to eq(['A title'])
    end
  end

  describe '#build_work_form' do
    let(:params) { ActionController::Parameters.new }
    let(:work_form) { instance_double(Hyrax::Forms::ResourceForm, deserialize: nil) }

    before do
      allow(presenter).to receive_messages(work_resource_class: double(new: double),
                                           selected_admin_set_id: nil)
      allow(Hyrax::Forms::ResourceForm).to receive(:for).and_return(work_form)
      allow(work_form).to receive(:prepopulate!).and_return(work_form)
      allow(Hyrax::FlexibleSchema).to receive(:current_schema_id).and_return(1)
    end

    it 'restores saved attributes with deserialize (not validate, which would show errors early)' do
      presenter.state.attributes = { 'item_subtype' => 'x' }
      presenter.build_work_form
      expect(work_form).to have_received(:deserialize).with('item_subtype' => 'x')
    end

    it 'does not deserialize when there is no saved state' do
      presenter.build_work_form
      expect(work_form).not_to have_received(:deserialize)
    end
  end

  describe '#visibility_fields' do
    let(:form) { double(object: object) }

    context 'with no embargo or lease' do
      let(:object) { double(embargo: nil, lease: nil, visibility: 'open') }

      it 'reports the flat visibility as current and defaults dates to tomorrow' do
        fields = presenter.visibility_fields(form)
        expect(fields.current).to eq('open')
        expect(fields.embargo_date).to eq(Time.zone.today + 1)
      end
    end

    context 'with an active embargo' do
      let(:object) do
        double(embargo: double(embargo_release_date: Time.zone.today + 5,
                               visibility_during_embargo: 'restricted',
                               visibility_after_embargo: 'open'),
               lease: nil, visibility: 'restricted')
      end

      it 'reports embargo as current and prefills its values' do
        fields = presenter.visibility_fields(form)
        expect(fields.current).to eq('embargo')
        expect(fields.embargo_during).to eq('restricted')
        expect(fields.embargo_date).to eq(Time.zone.today + 5)
      end
    end
  end

  describe '#show_review_destination?' do
    it 'is true only when there is more than one set and a name resolved' do
      allow(presenter).to receive_messages(multiple_admin_sets?: true, selected_admin_set_name: 'Theses')
      expect(presenter).to be_show_review_destination
    end

    it 'is false with a single set' do
      allow(presenter).to receive_messages(multiple_admin_sets?: false, selected_admin_set_name: 'Theses')
      expect(presenter).not_to be_show_review_destination
    end

    it 'is false when no name resolved' do
      allow(presenter).to receive_messages(multiple_admin_sets?: true, selected_admin_set_name: nil)
      expect(presenter).not_to be_show_review_destination
    end
  end

  describe '#file_type_label' do
    it 'returns the uppercase extension' do
      uf = double(file: double(file: double(filename: 'thesis.PDF')))
      expect(presenter.file_type_label(uf)).to eq('PDF')
    end

    it 'falls back to a generic label when there is no extension' do
      uf = double(file: double(file: double(filename: 'README')))
      expect(presenter.file_type_label(uf)).to eq(I18n.t('hyku.deposit_wizard.file_meta.file'))
    end
  end

  # Hyrax registers controlled vocabularies as two different kinds of object, and
  # the review step has to label values through both: most (audience, discipline,
  # resource_types, ...) are modules extending AuthorityService whose `label` is a
  # module method, while licenses and rights_statements are classes to instantiate.
  describe '#review_display_values' do
    let(:context) do
      double(session: session, current_user: nil, current_ability: nil,
             params: params, main_app: nil, blacklight_config: nil, helpers: helpers)
    end
    let(:helpers) { double }

    before { allow(helpers).to receive(:controlled_vocabulary_source_for).with(:a_term).and_return(source) }

    # Asserted on the resolved service rather than through the returned labels:
    # every module-backed vocabulary Hyrax ships labels its ids with themselves
    # ("Article" => "Article"), so a label comparison passes even when the service
    # failed to resolve and the raw value was echoed instead.
    context 'when the registered service is a module' do
      let(:source) { 'resource_types' }

      it 'uses the module itself rather than instantiating it' do
        expect(presenter.controlled_service_for(:a_term)).to be(Hyrax::ResourceTypesService)
      end

      it 'labels a value through it' do
        expect(presenter.review_display_values(:a_term, ['Article'])).to eq(['Article'])
      end
    end

    context 'when the registered service is a class' do
      let(:source) { 'licenses' }

      it 'instantiates it' do
        expect(presenter.controlled_service_for(:a_term)).to be_a(Hyrax::LicenseService)
      end

      it 'labels a value through the instance' do
        value = Hyrax::LicenseService.new.select_all_options.first.last

        expect(presenter.review_display_values(:a_term, [value]))
          .to eq([Hyrax::LicenseService.new.label(value)])
      end
    end

    context 'when the profile names a source with no registry entry' do
      let(:source) { 'not_registered_anywhere' }

      it 'falls back to a tolerant lookup and echoes the stored value' do
        expect(presenter.review_display_values(:a_term, ['unmatched'])).to eq(['unmatched'])
      end
    end

    context 'when the property is not controlled' do
      let(:source) { nil }

      it 'returns the values untouched' do
        expect(presenter.review_display_values(:a_term, %w[one two])).to eq(%w[one two])
      end
    end
  end
end
