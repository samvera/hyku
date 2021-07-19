# frozen_string_literal: true

RSpec.describe 'Site contact configuration' do
  context 'as an administrator' do
    let(:user) { FactoryBot.create(:admin) }

    before do
      login_as(user, scope: :user)
    end

    describe 'contact_email' do
      it 'updates the contact_email' do
        visit edit_site_contact_path
        fill_in 'Contact email', with: 'contact@email.com'
        click_on 'Save'
        expect(page).to have_current_path(edit_site_contact_path(locale: 'en'))
        expect(page).to have_field('Contact email')
        # used eq rather than be to compare value rather than the object itself
        expect(page.first(:css, "#site_contact_email")[:value]).to eq "contact@email.com"
      end
    end
  end
end
