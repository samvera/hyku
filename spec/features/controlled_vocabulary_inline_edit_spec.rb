# frozen_string_literal: true

RSpec.describe 'Editing a vocabulary in place', type: :feature, js: true, clean: true do
  let(:account) { FactoryBot.create(:account_with_public_schema) }
  let(:admin) { FactoryBot.create(:admin) }
  let(:vocabulary_path) { '/dashboard/controlled_vocabularies/inline_edit_rooms' }

  # The qa tables are seeded once in before(:suite) and skipped by truncation, so
  # each example works on a name of its own and clears it afterwards.
  before do
    allow(Account).to receive(:from_request).and_return(account)
    Hyrax::Group.create(name: 'admin')
    Qa::LocalAuthority.create!(name: 'inline_edit_rooms',
                               label: 'Reading Rooms',
                               description: 'Where an item may be consulted on site.')
    login_as admin
  end

  after { Qa::LocalAuthority.where(name: 'inline_edit_rooms').destroy_all }

  it 'opens the field on the page rather than following the pencil to the edit page' do
    visit vocabulary_path
    first('.vocabulary-field-edit').click

    expect(page).to have_css('#vocabulary-label-form input', visible: :visible)
    expect(page).to have_current_path(vocabulary_path, ignore_query: true)
    expect(page.evaluate_script('document.activeElement.name')).to eq 'local_authority[label]'
  end

  it 'returns focus to the pencil when the edit is cancelled' do
    visit vocabulary_path
    first('.vocabulary-field-edit').click
    first('.vocabulary-field-cancel').click

    expect(page).to have_css('#vocabulary-label-form', visible: :hidden)
    expect(page.evaluate_script('document.activeElement.className')).to include 'vocabulary-field-edit'
  end

  it 'saves the new wording' do
    visit vocabulary_path
    first('.vocabulary-field-edit').click
    within('#vocabulary-label-form') do
      fill_in 'local_authority[label]', with: 'Reading Areas'
      click_button 'Save changes'
    end

    expect(page).to have_content 'Reading Areas was updated.'
    expect(Qa::LocalAuthority.find_by(name: 'inline_edit_rooms').label).to eq 'Reading Areas'
  end
end
