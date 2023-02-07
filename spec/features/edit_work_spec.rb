# frozen_string_literal: true

# NOTE: If want to run spec in browser, you have to set "js: true"
RSpec.describe 'Editing an existing Work', type: :feature, js: true, clean: true do
  let(:admin_user) { create(:admin) }
  let(:work) { FactoryBot.create(:generic_work) }

  before do
    login_as admin_user
  end

  context 'sharing a work' do
    let!(:group) { FactoryBot.create(:group, name: 'dummy') }

    before do
      visit "/concern/generic_works/#{ERB::Util.url_encode(work.id)}/edit#share"
    end

    it 'displays the groups humanized name' do
      expect(page).to have_content 'Add Sharing'
      expect(page.has_select?('new_group_name_skel', with_options: [group.humanized_name])).to be true
    end
  end
end
