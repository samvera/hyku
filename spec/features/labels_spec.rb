# frozen_string_literal: true

RSpec.describe 'Site labels configuration' do
  context 'as an administrator' do
    let(:user) { FactoryBot.create(:admin) }

    before do
      login_as(user, scope: :user)
    end

    describe 'application name' do
      it 'updates the application name in the brand bar' do
        visit edit_site_labels_path
        fill_in 'Application name', with: 'Custom Name'
        click_on 'Save'
        expect(page).to have_css '.navbar-brand', text: 'Custom Name'
      end

      it 'updates the application name in the <head> <title>' do
        visit edit_site_labels_path
        fill_in 'Application name', with: 'Custom Name'
        click_on 'Save'

        expect(page).to have_css 'head title', text: 'Custom Name', visible: false
      end
    end

    describe 'institution name' do
      before do
        Site.update(
          application_name: 'Test',
          institution_name_full: 'fullname'
        )
      end

      it 'updates the institution name in the agreement text' do
        visit edit_site_labels_path
        fill_in 'Institution name', with: 'Custom Inst Name'
        click_on 'Save'

        visit hyrax.agreement_path
        expect(page).to have_content('fullname (Custom Inst Name) requires')
      end
    end

    describe 'institution name full' do
      before do
        Site.update(
          application_name: 'Test',
          institution_name: 'name'
        )
      end

      it 'updates the full institution name in the agreement text' do
        visit edit_site_labels_path
        fill_in 'Full institution name', with: 'Custom Full Inst Name'
        click_on 'Save'

        visit hyrax.agreement_path
        expect(page).to have_content('Custom Full Inst Name (name) requires')
      end
    end
  end
end
