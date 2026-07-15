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
      let(:params) { ActionController::Parameters.new(step: 'select_parent', parent_id: 'abc123') }

      it 'stores the parent and advances' do
        transition = presenter.advance_from('select_parent')
        expect(transition).to be_advance
        expect(presenter.state.parent_id).to eq('abc123')
      end
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
end
