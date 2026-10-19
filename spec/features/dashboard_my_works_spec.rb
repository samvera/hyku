# frozen_string_literal: true

require 'rails_helper'

# Manual Test Plan: "Dashboard My Works Index Page"
# The owner is an admin so Delete renders whatever HYKU_RESTRICT_CREATE_AND_DESTROY_PERMISSIONS is.
RSpec.describe 'Dashboard My Works index', type: :feature, clean: true do
  include ActiveSupport::Testing::TimeHelpers

  let(:owner) { create(:admin, email: 'my-works-owner@example.com') }
  let(:other_user) { create(:user, email: 'someone-else@example.com') }

  before do
    FactoryBot.create(:registered_group) unless Hyrax::Group.exists?(name: 'registered')
    FactoryBot.create(:admin_group) unless Hyrax::Group.exists?(name: 'admin')
    FactoryBot.create(:editors_group) unless Hyrax::Group.exists?(name: 'editors')
    FactoryBot.create(:depositors_group) unless Hyrax::Group.exists?(name: 'depositors')
    Hyrax::AdminSetCreateService.find_or_create_default_admin_set
    login_as owner
  end

  def make_work(title, user: owner, visibility: 'open')
    FactoryBot.valkyrie_create(:generic_work_resource, title: [title], creator: ['My Works Tester'],
                                                       depositor: user.user_key, edit_users: [user],
                                                       visibility_setting: visibility)
  end

  def listed_titles
    # Each title link also holds an sr-only "Display all details of" prefix.
    all('table.works-list a.document-title').map { |a| a.text.sub('Display all details of', '').strip }
  end

  describe 'page header buttons' do
    # Potential duplicate: spec/features/create_work_spec.rb:51 (Add New Work button on my works)
    # Potential duplicate: spec/features/work_editor_role_spec.rb:73 (Add New Work button on my works)
    it 'shows "Create batch of works" when batch upload is enabled, alongside "Add New Work"' do
      allow(Flipflop).to receive(:batch_upload?).and_return(true)
      visit '/dashboard/my/works'

      # Several work types are enabled, so both buttons open the work-type modal.
      expect(page).to have_css('a[data-create-type="batch"][data-target="#worktypes-to-create"]', exact_text: 'Create batch of works')
      expect(page).to have_css('#add-new-work-button[data-create-type="single"]', exact_text: 'Add New Work')
    end

    it 'hides "Create batch of works" when batch upload is disabled' do
      allow(Flipflop).to receive(:batch_upload?).and_return(false)
      visit '/dashboard/my/works'

      expect(page).to have_link('Add New Work')
      expect(page).not_to have_link('Create batch of works')
    end
  end

  # Potential duplicate: spec/features/work_editor_role_spec.rb:47 ("works you own" header and own work listed)
  it 'counts and lists only the works the user owns' do
    make_work('Owned Alpha Work')
    make_work('Owned Beta Work')
    make_work('Owned Gamma Work', visibility: 'restricted')
    make_work('Someone Elses Work', user: other_user)

    visit '/dashboard/my/works'

    expect(page).to have_css('.count-display', exact_text: '3 works you own in the repository')
    expect(listed_titles).to contain_exactly('Owned Alpha Work', 'Owned Beta Work', 'Owned Gamma Work')
    expect(page).not_to have_content('Someone Elses Work')
  end

  it 'shows Title, Last modified, Highlighted, Visibility and Actions for each work' do
    highlighted = travel_to(Time.zone.local(2021, 3, 4, 12)) { make_work('Starred Listing Work') }
    plain = travel_to(Time.zone.local(2022, 5, 6, 12)) { make_work('Unstarred Private Work', visibility: 'restricted') }
    owner.trophies.create!(work_id: highlighted.id)

    visit '/dashboard/my/works'

    within('table.works-list thead') do
      expect(page).to have_css('th', exact_text: 'Title')
      # The plan calls this column "Date Added"; Hyrax's my/works/_default_group heading is
      # "Last modified" and Hyku's _list_works renders document.date_modified under it.
      expect(page).to have_css('th', exact_text: 'Last modified')
      expect(page).to have_css('th', exact_text: 'Highlighted')
      expect(page).to have_css('th', exact_text: 'Visibility of Work')
      expect(page).to have_css('th', exact_text: 'Actions')
    end

    within("#document_#{highlighted.id}") do
      expect(page).to have_link('Starred Listing Work', href: %r{/concern/generic_works/#{highlighted.id}})
      expect(page).to have_css('td.date', exact_text: '2021-03-04')
      expect(page).to have_css('span.fa-star.highlighted-work')
      expect(page).to have_link('Public', href: %r{/concern/generic_works/#{highlighted.id}/edit.*#share})
    end
    within("#document_#{plain.id}") do
      expect(page).to have_css('td.date', exact_text: '2022-05-06')
      expect(page).to have_css('span.fa-star-o.trophy-off')
      expect(page).not_to have_css('span.highlighted-work')
      expect(page).to have_link('Private', href: %r{/concern/generic_works/#{plain.id}/edit.*#share})
    end
  end

  it 'renders the date column from date_modified, not the date the work was added' do
    work = travel_to(Time.zone.local(2020, 1, 2, 12)) { make_work('Revised Later Work') }
    travel_to(Time.zone.local(2023, 7, 8, 12)) do
      saved = Hyrax.persister.save(resource: Hyrax.query_service.find_by(id: work.id))
      Hyrax.index_adapter.save(resource: saved)
    end

    visit '/dashboard/my/works'

    within("#document_#{work.id}") { expect(page).to have_css('td.date', exact_text: '2023-07-08') }
  end

  describe 'sorting, paging and searching' do
    it 'reorders the list from the sort dropdown' do
      travel_to(Time.zone.local(2019, 1, 1, 12)) { make_work('Oldest Sorted Work') }
      travel_to(Time.zone.local(2020, 1, 1, 12)) { make_work('Middle Sorted Work') }
      travel_to(Time.zone.local(2021, 1, 1, 12)) { make_work('Newest Sorted Work') }

      visit '/dashboard/my/works'
      # Default sort is "date uploaded ▼".
      expect(page).to have_button(text: 'Sort by date uploaded ▼')
      expect(listed_titles).to eq(['Newest Sorted Work', 'Middle Sorted Work', 'Oldest Sorted Work'])

      within('#sort-dropdown') { click_link 'date uploaded ▲' }

      expect(page).to have_button(text: 'Sort by date uploaded ▲')
      expect(listed_titles).to eq(['Oldest Sorted Work', 'Middle Sorted Work', 'Newest Sorted Work'])
    end

    it 'filters to the matching work from the search bar' do
      make_work('Zanzibar Spice Ledger')
      make_work('Arctic Survey Notes')

      visit '/dashboard/my/works'
      fill_in 'search-field-header', with: 'Zanzibar'
      click_button 'search-submit-header'

      expect(listed_titles).to eq(['Zanzibar Spice Ledger'])
      expect(page).to have_css('.count-display', exact_text: '1 works you own in the repository')
      expect(page).not_to have_content('Arctic Survey Notes')
    end

    it 'changes how many works are shown from the per-page dropdown', js: true do
      11.times { |i| make_work(format('Paged Work %02d', i + 1)) }

      visit '/dashboard/my/works'
      expect(page).to have_css('.count-display', exact_text: '11 works you own in the repository')
      expect(page).to have_css('table.works-list tbody tr', count: 10)

      # Hyrax's select_submit.js submits the per_page form on change.
      select '20', from: 'per_page'

      expect(page).to have_current_path(/per_page=20/)
      expect(page).to have_css('table.works-list tbody tr', count: 11)
    end
  end

  describe 'row actions' do
    let!(:work) { make_work('Actionable Row Work') }

    # Potential duplicate: spec/features/work_editor_role_spec.rb:136 (Edit action in my works row)
    # Potential duplicate: spec/features/transfers_and_proxies_spec.rb:25 (Transfer Ownership row action)
    it 'offers Edit, Delete, Highlight and Transfer actions; Edit opens the work form' do
      visit '/dashboard/my/works'

      within("#document_#{work.id}") do
        expect(page).to have_button('Select')
        expect(page).to have_link('Delete Work', href: %r{/concern/generic_works/#{work.id}})
        expect(page).to have_link('Highlight Work on Profile')
        expect(page).to have_link('Transfer Ownership of Work', href: %r{/works/#{work.id}/transfers/new})
        click_link 'Edit Work'
      end

      expect(page).to have_current_path(%r{\A/concern/generic_works/#{work.id}/edit})
      expect(page).to have_field('generic_work_title', with: 'Actionable Row Work')
    end

    it 'Delete Work removes the work' do
      keeper = make_work('Surviving Row Work')
      visit '/dashboard/my/works'

      # rack_test follows data-method="delete" and skips the data-confirm dialog.
      within("#document_#{work.id}") { click_link 'Delete Work' }

      expect(page).to have_content('Deleted Actionable Row Work')
      expect { Hyrax.query_service.find_by(id: work.id) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      expect(listed_titles).to eq(['Surviving Row Work'])
      expect(Hyrax.query_service.find_by(id: keeper.id)).to be_present
    end

    it 'Highlight Work on Profile highlights the work in the list and on the profile', js: true do
      visit '/dashboard/my/works'

      within("#document_#{work.id}") do
        expect(page).to have_css('span.fa-star-o.trophy-off')
        find("#dropdownMenu_#{work.id}").click
        click_link 'Highlight Work on Profile'
        # trophy.js flips the link to trophy-on once the toggle request succeeds.
        expect(page).to have_css('#action-highlight-work.trophy-on', visible: :all)
      end
      expect(owner.trophies.where(work_id: work.id.to_s)).to exist

      visit '/dashboard/my/works'
      within("#document_#{work.id}") { expect(page).to have_css('span.fa-star.highlighted-work') }

      visit "/dashboard/profiles/#{owner.to_param}"
      within('tr.highlighted-works') { expect(page).to have_link('Actionable Row Work') }
    end
  end
end
