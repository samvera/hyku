# frozen_string_literal: true

RSpec.describe 'Editing a vocabulary in place', type: :feature, js: true, clean: true do
  let(:account) { FactoryBot.create(:account_with_public_schema) }
  let(:admin) { FactoryBot.create(:admin) }

  before do
    allow(Account).to receive(:from_request).and_return(account)
    Hyrax::Group.create(name: 'admin')
    # The suite seeds the shipped vocabularies once, and these examples share that
    # schema, so the row may outlive the example that wrote it.
    Qa::LocalAuthority.find_or_create_by!(name: 'reading_rooms')
                      .update!(label: 'Reading Rooms',
                               description: 'Where an item may be consulted on site.')
    login_as admin
  end

  it 'opens the field on the page rather than following the pencil to the edit page' do
    visit '/dashboard/controlled_vocabularies/reading_rooms'
    find('#vocabulary-label-form', visible: false)
    first('.vocabulary-field-edit').click

    expect(page).to have_css('#vocabulary-label-form input', visible: true)
    expect(page).to have_current_path('/dashboard/controlled_vocabularies/reading_rooms', ignore_query: true)
    expect(page.evaluate_script('document.activeElement.name')).to eq 'local_authority[label]'
  end

  it 'returns focus to the pencil when the edit is cancelled' do
    visit '/dashboard/controlled_vocabularies/reading_rooms'
    first('.vocabulary-field-edit').click
    first('.vocabulary-field-cancel').click

    expect(page).to have_css('#vocabulary-label-form', visible: false)
    expect(page.evaluate_script('document.activeElement.className')).to include 'vocabulary-field-edit'
  end

  it 'saves the new wording' do
    visit '/dashboard/controlled_vocabularies/reading_rooms'
    first('.vocabulary-field-edit').click
    fill_in 'local_authority[label]', with: 'Reading Areas'
    click_button 'Save changes'

    expect(page).to have_content 'Reading Areas was updated.'
    expect(Qa::LocalAuthority.find_by(name: 'reading_rooms').label).to eq 'Reading Areas'
  end
end
