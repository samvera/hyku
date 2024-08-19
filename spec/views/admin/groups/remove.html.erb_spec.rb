# frozen_string_literal: true

RSpec.describe 'admin/groups/remove', type: :view do
  include Warden::Test::Helpers
  include Devise::Test::ControllerHelpers

  context 'groups index page' do
    let(:group) { FactoryBot.create(:group) }

    before do
      allow(controller).to receive(:params).and_return(
        controller: 'admin/groups',
        action: 'remove',
        id: group.id
      )
      assign(:group, group)
      render
    end

    it 'has the "Remove" tab in an active state' do
      expect(rendered).to have_selector('.nav-tabs .nav-item a.nav-link.active', text: 'Remove')
    end

    it 'has tabs for other actions on the group' do
      expect(rendered).to have_selector('.nav-tabs .nav-item a.nav-link', text: 'Description')
      expect(rendered).to have_selector('.nav-tabs .nav-item a.nav-link', text: 'Users')
    end

    it 'has a delete button' do
      expect(rendered).to have_selector('a', class: 'action-delete')
    end
  end
end
