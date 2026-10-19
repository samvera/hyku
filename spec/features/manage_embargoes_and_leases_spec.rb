# frozen_string_literal: true

require 'rails_helper'

# Pages come from the hyrax gem (Hyrax::EmbargoesController / LeasesController) and list Solr records.
# Hyrax only indexes a release date while the embargo/lease is active, so an "expired but still
# active" record is created time-travelled to before its (past) date, as happens in production.
RSpec.describe 'Manage embargoes and leases', type: :feature, clean: true do
  include ActiveSupport::Testing::TimeHelpers

  let(:admin) { create(:admin) }
  let(:future_date) { (Time.zone.today + 30).to_datetime }
  let(:past_date) { (Time.zone.today - 5).to_datetime }

  before do
    FactoryBot.create(:registered_group) unless Hyrax::Group.exists?(name: 'registered')
    FactoryBot.create(:admin_group) unless Hyrax::Group.exists?(name: 'admin')
    FactoryBot.create(:editors_group) unless Hyrax::Group.exists?(name: 'editors')
    FactoryBot.create(:depositors_group) unless Hyrax::Group.exists?(name: 'depositors')
    Hyrax::AdminSetCreateService.find_or_create_default_admin_set
    login_as admin
  end

  # Hyrax::EmbargoPresenter / LeasePresenter render dates with to_formatted_s(:rfc822).
  def display_date(date)
    date.strftime('%d %b %Y')
  end

  def find_resource(resource)
    Hyrax.query_service.find_by(id: resource.id)
  end

  def work_with(title, members: nil, **restriction)
    FactoryBot.valkyrie_create(:generic_work_resource, title: [title], creator: ['Restriction Tester'],
                                                       rights_statement: ['http://rightsstatements.org/vocab/InC/1.0/'],
                                                       members:, **restriction)
  end

  def embargo(release_date:, during: 'restricted', after: 'open')
    FactoryBot.valkyrie_create(:hyrax_embargo, embargo_release_date: release_date,
                                               visibility_during_embargo: during,
                                               visibility_after_embargo: after)
  end

  def lease(expiration_date:, during: 'open', after: 'authenticated')
    FactoryBot.valkyrie_create(:hyrax_lease, lease_expiration_date: expiration_date,
                                             visibility_during_lease: during,
                                             visibility_after_lease: after)
  end

  describe 'Manage Embargoes' do
    def embargoed_work(title, release_date: future_date, after: 'open', members: nil)
      work_with(title, members:, embargo: embargo(release_date:, after:))
    end

    def expired_embargoed_work(title)
      release_date = past_date
      travel_to(release_date - 5.days) { embargoed_work(title, release_date:) }
    end

    def deactivated_embargoed_work(title)
      embargoed_work(title, after: 'authenticated').tap { |w| Hyrax::Actors::EmbargoActor.new(w).destroy }
    end

    # Manual Test Plan: "Manage Embargoes Index Page"
    describe 'index page' do
      let!(:active_work) { embargoed_work('Active Embargo Work', after: 'open') }
      let!(:active_file_set) do
        FactoryBot.valkyrie_create(:hyrax_file_set, title: ['Active Embargo File'],
                                                    embargo: embargo(release_date: future_date, after: 'authenticated'))
      end
      let!(:expired_work) { expired_embargoed_work('Expired Embargo Work') }
      let!(:deactivated_work) { deactivated_embargoed_work('Deactivated Embargo Work') }
      let!(:unrestricted_work) { work_with('Never Embargoed Work') }

      # Potential duplicate: spec/requests/admin_dashboard_spec.rb:103 (GET /embargoes renders for an admin)
      it 'lists every enforced embargo (works and file sets) under All Active Embargoes' do
        visit '/embargoes'

        expect(page).to have_css('h1', text: 'Manage Embargoes')
        expect(page).to have_link('All Active Embargoes', href: '#active')
        within('#active') do
          expect(page).to have_css('th', text: 'Type of Item')
          expect(page).to have_css('th', text: 'Title')
          expect(page).to have_css('th', text: 'Current Visibility')
          expect(page).to have_css('th', text: 'Embargo Release Date')
          expect(page).to have_css('th', text: 'Visibility will Change to')

          within(find('tr', text: 'Active Embargo Work')) do
            expect(page).to have_css('td.human-readable-type', exact_text: 'Work')
            expect(page).to have_link('Active Embargo Work', href: %r{/embargoes/#{active_work.id}/edit})
            expect(page).to have_css('td.current-visibility .badge', exact_text: 'Embargo')
            expect(page).to have_css('td.embargo-release-date', exact_text: display_date(future_date))
            expect(page).to have_css('td.visibility-after-embargo .badge', exact_text: 'Public')
          end
          within(find('tr', text: 'Active Embargo File')) do
            expect(page).to have_css('td.human-readable-type', exact_text: 'File Set')
            expect(page).to have_link('Active Embargo File', href: %r{/embargoes/#{active_file_set.id}/edit})
            expect(page).to have_css('td.current-visibility .badge', exact_text: 'Embargo')
            expect(page).to have_css('td.embargo-release-date', exact_text: display_date(future_date))
            expect(page).to have_css('td.visibility-after-embargo .badge', exact_text: 'Institution')
          end
          # Hyrax lists every *enforced* embargo here, expired or not (EmbargoService.assets_under_embargo).
          within(find('tr', text: 'Expired Embargo Work')) do
            expect(page).to have_css('td.embargo-release-date', exact_text: display_date(past_date))
          end
          expect(page).to have_css('tbody tr', count: 3)
          expect(page).not_to have_content('Deactivated Embargo Work')
          expect(page).not_to have_content('Never Embargoed Work')
        end
      end

      it 'lists only past-due, still-enforced embargoes under Expired Active Embargoes' do
        visit '/embargoes'

        expect(page).to have_link('Expired Active Embargoes', href: '#expired')
        within('#expired') do
          expect(page).to have_css('th', text: 'Type of Item')
          expect(page).to have_css('th', text: 'Current Visibility')
          expect(page).to have_css('th', text: 'Embargo Release Date')
          expect(page).to have_css('th', text: 'Visibility will Change to')
          within(find('tr', text: 'Expired Embargo Work', match: :first)) do
            expect(page).to have_css('td.human-readable-type', exact_text: 'Work')
            expect(page).to have_link('Expired Embargo Work', href: %r{/embargoes/#{expired_work.id}/edit})
            expect(page).to have_css('td.current-visibility .badge', exact_text: 'Embargo')
            expect(page).to have_css('td.embargo-release-date', exact_text: display_date(past_date))
            expect(page).to have_css('td.visibility-after-embargo .badge', exact_text: 'Public')
          end
          expect(page).not_to have_content('Active Embargo Work')
          expect(page).not_to have_content('Active Embargo File')
          expect(page).not_to have_content('Deactivated Embargo Work')
          expect(page).not_to have_content('Never Embargoed Work')
        end
      end

      it 'releases selected expired embargoes with "Deactivate Embargoes for Selected"' do
        visit '/embargoes'

        within('#expired') do
          check "batch_document_#{expired_work.id}"
          click_button 'Deactivate Embargoes for Selected'
        end

        expect(page).to have_current_path(%r{\A/embargoes})
        expect(page).to have_content('Deactivation succeeded!')
        released = find_resource(expired_work)
        expect(released.visibility).to eq('open')
        within('#expired') { expect(page).to have_content('There are no expired embargoes in effect at this time.') }
        within('#active') { expect(page).not_to have_content('Expired Embargo Work') }
        # The still-active embargo was not touched.
        expect(find_resource(active_work).embargo.embargo_release_date).to be_present
      end

      # Remove this comment and the `pending` call to re-enable this test when issue #xxxx is fixed.
      # KNOWN APPLICATION ISSUE: batch deactivate never saves the released embargo. Fix goes in Hyrax (samvera/hyrax): app/controllers/concerns/hyrax/embargoes_controller_behavior.rb#update.
      it 'records the batch-released embargo in its history and under Deactivated Embargoes' do
        pending('EmbargoesControllerBehavior#update (Valkyrie) calls EmbargoManager#release! but never persists resource.embargo')
        visit '/embargoes'
        within('#expired') do
          check "batch_document_#{expired_work.id}"
          click_button 'Deactivate Embargoes for Selected'
        end

        expect(find_resource(expired_work).embargo.embargo_history.last.to_s).to include('An expired embargo was deactivated')
        within('#deactivated') { expect(page).to have_link('Expired Embargo Work') }
      end

      it 'lists deactivated embargoes with their current visibility and history' do
        visit '/embargoes'

        expect(page).to have_link('Deactivated Embargoes', href: '#deactivated')
        within('#deactivated') do
          expect(page).to have_link('Deactivated Embargo Work', href: %r{/embargoes/#{deactivated_work.id}/edit})
          # Released to its "after" visibility (Institution).
          expect(page).to have_css('.badge', exact_text: 'Institution')
          expect(page).to have_css('li', text: /An active embargo was deactivated on .*Its release date was #{future_date.strftime('%Y-%m-%d')}/)
          expect(page).not_to have_content('Active Embargo Work')
          expect(page).not_to have_content('Active Embargo File')
          expect(page).not_to have_content('Expired Embargo Work')
          expect(page).not_to have_content('Never Embargoed Work')
        end
      end
    end

    # Manual Test Plan: "Manage Embargoes Edit Page"
    describe 'edit page' do
      let!(:work) { embargoed_work('Editable Embargo Work', after: 'open') }

      it 'shows the current embargo in an editable form and Update changes it' do
        visit "/embargoes/#{work.id}/edit"

        expect(page).to have_css('h1', text: 'Manage Embargoes for Editable Embargo Work (Work)')
        expect(page).to have_css('h2', text: 'Current Embargo')
        expect(page).to have_content('This Work is under embargo.')
        expect(page).to have_select('Restricted to', selected: 'Private')
        expect(page).to have_field('until', with: future_date.strftime('%Y-%m-%d'))
        expect(page).to have_select('then open it up to', selected: 'Public')

        new_date = Time.zone.today + 90
        fill_in 'until', with: new_date.to_s
        select 'Institution', from: 'then open it up to'
        click_button 'Update Embargo'

        updated = find_resource(work).embargo
        expect(updated.embargo_release_date.to_date).to eq(new_date)
        expect(updated.visibility_after_embargo).to eq('authenticated')
      end

      it 'Deactivate Embargo releases the embargo and records it under Past Embargoes' do
        visit "/embargoes/#{work.id}/edit"
        expect(page).to have_css('h2', text: 'Past Embargoes')
        expect(page).to have_content('This Work has no previous embargoes applied to it.')

        click_link 'Deactivate Embargo'

        # A work without file sets goes straight back to its edit page.
        expect(page).to have_current_path(%r{\A/embargoes/#{work.id}/edit})
        expect(page).to have_content('This Work is not currently under embargo.')
        expect(page).to have_button('Apply Embargo')
        expect(page).not_to have_link('Deactivate Embargo')
        expect(page).to have_css('li', text: /An active embargo was deactivated on .*Its release date was #{future_date.strftime('%Y-%m-%d')}/)

        reloaded = find_resource(work)
        expect(reloaded.visibility).to eq('open')
        expect(reloaded.embargo.embargo_release_date).to be_nil
        expect(reloaded.embargo.embargo_history.size).to eq(1)
      end

      it 'Cancel returns to Manage Embargoes and the return link opens the work edit page' do
        visit "/embargoes/#{work.id}/edit"
        click_link 'Cancel and manage all embargoes'
        expect(page).to have_current_path(%r{\A/embargoes(\?|\z)})
        expect(page).to have_css('h1', text: 'Manage Embargoes')

        visit "/embargoes/#{work.id}/edit"
        click_link 'Return to editing this Work'
        expect(page).to have_current_path(%r{\A/concern/generic_works/#{work.id}/edit})
      end

      it 'links a file set embargo back to the file set edit page' do
        file_set = FactoryBot.valkyrie_create(:hyrax_file_set, title: ['Editable Embargo File'],
                                                               embargo: embargo(release_date: future_date))
        visit "/embargoes/#{file_set.id}/edit"

        expect(page).to have_css('h1', text: 'Manage Embargoes for Editable Embargo File (File Set)')
        expect(page).to have_link('Return to editing this File Set', href: %r{/concern/file_sets/#{file_set.id}/edit})
      end
    end

    # Manual Test Plan: "Manage Embargoes Deactivate Page"
    describe 'deactivating the embargo of a work with file sets' do
      let!(:file_set) do
        FactoryBot.valkyrie_create(:hyrax_file_set, title: ['Embargoed Member File'],
                                                    embargo: embargo(release_date: future_date))
      end
      let!(:work) { embargoed_work('Embargoed Parent Work', members: [file_set]) }

      before do
        visit "/embargoes/#{work.id}/edit"
        click_link 'Deactivate Embargo'
      end

      it 'asks whether to apply the change to the files, offering both choices' do
        expect(page).to have_current_path(%r{\A/concern/permissions/#{work.id}/confirm})
        expect(page).to have_content('Apply changes to contents?')
        expect(page).to have_content('An active embargo was deactivated')
        expect(page).to have_button('Yes please.')
        expect(page).to have_link("No. I'll update it manually.", href: %r{/concern/generic_works/#{work.id}})
        expect(find_resource(work).visibility).to eq('open')
      end

      # Remove this comment and the `pending` call to re-enable this test when issue #xxxx is fixed.
      # KNOWN APPLICATION ISSUE: confirm page names a Valkyrie work "GenericWorkResource: <id>", not its title. Fix goes in Hyrax (samvera/hyrax): app/views/hyrax/permissions/confirm.html.erb.
      it 'names the work by its title on the confirmation page' do
        pending('hyrax/permissions/confirm renders curation_concern.to_s, which is not the title for a Valkyrie resource')
        expect(page).to have_css('.permissions-confirm i', exact_text: 'Embargoed Parent Work')
      end

      it '"Yes please." copies the released visibility to the files, lifting their embargo' do
        perform_enqueued_jobs { click_button 'Yes please.' }

        expect(page).to have_current_path(%r{\A/concern/generic_works/#{work.id}})
        expect(find_resource(file_set).visibility).to eq('open')

        visit '/embargoes'
        within('#active') { expect(page).not_to have_content('Embargoed Member File') }
      end

      it '"No. I\'ll update it manually." leaves the file embargoes in place' do
        perform_enqueued_jobs { click_link "No. I'll update it manually." }

        expect(page).to have_current_path(%r{\A/concern/generic_works/#{work.id}})
        expect(find_resource(file_set).visibility).to eq('restricted')

        visit '/embargoes'
        within('#active') do
          expect(page).to have_link('Embargoed Member File')
          expect(page).not_to have_content('Embargoed Parent Work')
        end
      end
    end
  end

  describe 'Manage Leases' do
    def leased_work(title, expiration_date: future_date, after: 'authenticated', members: nil)
      work_with(title, members:, lease: lease(expiration_date:, after:))
    end

    def expired_leased_work(title)
      expiration_date = past_date
      travel_to(expiration_date - 5.days) { leased_work(title, expiration_date:) }
    end

    def deactivated_leased_work(title)
      leased_work(title, after: 'restricted').tap { |w| Hyrax::Actors::LeaseActor.new(w).destroy }
    end

    # Manual Test Plan: "Manage Leases Index Page"
    describe 'index page' do
      let!(:active_work) { leased_work('Active Lease Work', after: 'authenticated') }
      let!(:active_file_set) do
        FactoryBot.valkyrie_create(:hyrax_file_set, :public, title: ['Active Lease File'],
                                                             lease: lease(expiration_date: future_date, after: 'restricted'))
      end
      let!(:expired_work) { expired_leased_work('Expired Lease Work') }
      let!(:deactivated_work) { deactivated_leased_work('Deactivated Lease Work') }
      let!(:unrestricted_work) { work_with('Never Leased Work') }

      # Potential duplicate: spec/requests/admin_dashboard_spec.rb:109 (GET /leases renders for an admin)
      it 'lists every enforced lease (works and file sets) under All Active Leases' do
        visit '/leases'

        expect(page).to have_css('h1', text: 'Manage Leases')
        expect(page).to have_link('All Active Leases', href: '#active')
        within('#active') do
          expect(page).to have_css('th', text: 'Type of Item')
          expect(page).to have_css('th', text: 'Title')
          expect(page).to have_css('th', text: 'Current Visibility')
          expect(page).to have_css('th', text: 'Lease Release Date')
          expect(page).to have_css('th', text: 'Visibility will Change to')

          within(find('tr', text: 'Active Lease Work')) do
            expect(page).to have_css('td.human-readable-type', exact_text: 'Work')
            expect(page).to have_link('Active Lease Work', href: %r{/leases/#{active_work.id}/edit})
            expect(page).to have_css('td.current-visibility .badge', exact_text: 'Lease')
            expect(page).to have_css('td.lease-expiration-date', exact_text: display_date(future_date))
            expect(page).to have_css('td.visibility-after-lease .badge', exact_text: 'Institution')
          end
          within(find('tr', text: 'Active Lease File')) do
            expect(page).to have_css('td.human-readable-type', exact_text: 'File Set')
            expect(page).to have_link('Active Lease File', href: %r{/leases/#{active_file_set.id}/edit})
            expect(page).to have_css('td.current-visibility .badge', exact_text: 'Lease')
            expect(page).to have_css('td.lease-expiration-date', exact_text: display_date(future_date))
            expect(page).to have_css('td.visibility-after-lease .badge', exact_text: 'Private')
          end
          # Hyrax lists every *enforced* lease here, expired or not (LeaseService.assets_under_lease).
          within(find('tr', text: 'Expired Lease Work')) do
            expect(page).to have_css('td.lease-expiration-date', exact_text: display_date(past_date))
          end
          expect(page).to have_css('tbody tr', count: 3)
          expect(page).not_to have_content('Deactivated Lease Work')
          expect(page).not_to have_content('Never Leased Work')
        end
      end

      it 'lists only past-due, still-enforced leases under Expired Active Leases' do
        visit '/leases'

        expect(page).to have_link('Expired Active Leases', href: '#expired')
        within('#expired') do
          expect(page).to have_css('th', text: 'Type of Item')
          expect(page).to have_css('th', text: 'Current Visibility')
          expect(page).to have_css('th', text: 'Lease Release Date')
          expect(page).to have_css('th', text: 'Visibility will Change to')
          within(find('tr', text: 'Expired Lease Work', match: :first)) do
            expect(page).to have_css('td.human-readable-type', exact_text: 'Work')
            expect(page).to have_link('Expired Lease Work', href: %r{/leases/#{expired_work.id}/edit})
            expect(page).to have_css('td.current-visibility .badge', exact_text: 'Lease')
            expect(page).to have_css('td.lease-release-date', exact_text: display_date(past_date))
            expect(page).to have_css('td.visibility-after-lease .badge', exact_text: 'Institution')
          end
          expect(page).not_to have_content('Active Lease Work')
          expect(page).not_to have_content('Active Lease File')
          expect(page).not_to have_content('Deactivated Lease Work')
          expect(page).not_to have_content('Never Leased Work')
        end
      end

      it 'releases selected expired leases with "Deactivate Leases for Selected"' do
        visit '/leases'

        within('#expired') do
          check "batch_document_#{expired_work.id}"
          click_button 'Deactivate Leases for Selected'
        end

        expect(page).to have_current_path(%r{\A/leases})
        released = find_resource(expired_work)
        expect(released.visibility).to eq('authenticated')
        within('#expired') { expect(page).to have_content('There are no expired leases in effect at this time.') }
        within('#active') { expect(page).not_to have_content('Expired Lease Work') }
        # The still-active lease was not touched.
        expect(find_resource(active_work).lease.lease_expiration_date).to be_present
      end

      # Remove this comment and the `pending` call to re-enable this test when issue #xxxx is fixed.
      # KNOWN APPLICATION ISSUE: batch deactivate never saves the released lease. Fix goes in Hyrax (samvera/hyrax): app/controllers/concerns/hyrax/leases_controller_behavior.rb#update.
      it 'records the batch-released lease in its history and under Deactivated Leases' do
        pending('LeasesControllerBehavior#update (Valkyrie) calls LeaseManager#release! but never persists resource.lease')
        visit '/leases'
        within('#expired') do
          check "batch_document_#{expired_work.id}"
          click_button 'Deactivate Leases for Selected'
        end

        expect(find_resource(expired_work).lease.lease_history.last.to_s).to include('An expired lease was deactivated')
        within('#deactivated') { expect(page).to have_link('Expired Lease Work') }
      end

      it 'lists deactivated leases with their current visibility and history' do
        visit '/leases'

        expect(page).to have_link('Deactivated Leases', href: '#deactivated')
        within('#deactivated') do
          expect(page).to have_link('Deactivated Lease Work', href: %r{/leases/#{deactivated_work.id}/edit})
          # Released to its "after" visibility (Private).
          expect(page).to have_css('.badge', exact_text: 'Private')
          expect(page).to have_css('li', text: /An active lease was deactivated on .*Its expiration date was #{future_date.strftime('%Y-%m-%d')}/)
          expect(page).not_to have_content('Active Lease Work')
          expect(page).not_to have_content('Active Lease File')
          expect(page).not_to have_content('Expired Lease Work')
          expect(page).not_to have_content('Never Leased Work')
        end
      end
    end

    # Manual Test Plan: "Manage Leases Edit Page"
    describe 'edit page' do
      let!(:work) { leased_work('Editable Lease Work', after: 'authenticated') }

      it 'shows the current lease in an editable form and Update changes it' do
        visit "/leases/#{work.id}/edit"

        expect(page).to have_css('h1', text: 'Manage Leases for Editable Lease Work (Work)')
        expect(page).to have_css('h2', text: 'Current Lease')
        expect(page).to have_content('This Work is under lease.')
        expect(page).to have_select('generic_work_visibility_during_lease', selected: 'Public')
        expect(page).to have_field('generic_work_lease_expiration_date', with: future_date.strftime('%Y-%m-%d'))
        expect(page).to have_select('generic_work_visibility_after_lease', selected: 'Institution')

        new_date = Time.zone.today + 90
        fill_in 'generic_work_lease_expiration_date', with: new_date.to_s
        select 'Private', from: 'generic_work_visibility_after_lease'
        click_button 'Update Lease'

        updated = find_resource(work).lease
        expect(updated.lease_expiration_date.to_date).to eq(new_date)
        expect(updated.visibility_after_lease).to eq('restricted')
      end

      it 'Deactivate Lease releases the lease and records it under Past Leases' do
        visit "/leases/#{work.id}/edit"
        expect(page).to have_css('h2', text: 'Past Leases')
        expect(page).to have_content('This Work has no previous leases applied to it.')

        click_link 'Deactivate Lease'

        expect(page).to have_current_path(%r{\A/leases/#{work.id}/edit})
        expect(page).to have_content('This Work is not currently under lease.')
        expect(page).to have_button('Apply Lease')
        expect(page).not_to have_link('Deactivate Lease')
        expect(page).to have_css('li', text: /An active lease was deactivated on .*Its expiration date was #{future_date.strftime('%Y-%m-%d')}/)

        reloaded = find_resource(work)
        expect(reloaded.visibility).to eq('authenticated')
        expect(reloaded.lease.lease_expiration_date).to be_nil
        expect(reloaded.lease.lease_history.size).to eq(1)
      end

      it 'Cancel returns to Manage Leases and the return link opens the work edit page' do
        visit "/leases/#{work.id}/edit"
        click_link 'Cancel and manage all leases'
        expect(page).to have_current_path(%r{\A/leases(\?|\z)})
        expect(page).to have_css('h1', text: 'Manage Leases')

        visit "/leases/#{work.id}/edit"
        click_link 'Return to editing this Work'
        expect(page).to have_current_path(%r{\A/concern/generic_works/#{work.id}/edit})
      end

      it 'links a file set lease back to the file set edit page' do
        file_set = FactoryBot.valkyrie_create(:hyrax_file_set, :public, title: ['Editable Lease File'],
                                                                        lease: lease(expiration_date: future_date))
        visit "/leases/#{file_set.id}/edit"

        expect(page).to have_css('h1', text: 'Manage Leases for Editable Lease File (File Set)')
        expect(page).to have_link('Return to editing this File Set', href: %r{/concern/file_sets/#{file_set.id}/edit})
      end
    end

    # Manual Test Plan: "Manage Leases Deactivate Page"
    describe 'deactivating the lease of a work with file sets' do
      let!(:file_set) do
        FactoryBot.valkyrie_create(:hyrax_file_set, :public, title: ['Leased Member File'],
                                                             lease: lease(expiration_date: future_date))
      end
      let!(:work) { leased_work('Leased Parent Work', members: [file_set]) }

      before do
        visit "/leases/#{work.id}/edit"
        click_link 'Deactivate Lease'
      end

      it 'asks whether to apply the change to the files, offering both choices' do
        expect(page).to have_current_path(%r{\A/concern/permissions/#{work.id}/confirm})
        expect(page).to have_content('Apply changes to contents?')
        expect(page).to have_content('An active lease was deactivated')
        expect(page).to have_button('Yes please.')
        expect(page).to have_link("No. I'll update it manually.", href: %r{/concern/generic_works/#{work.id}})
        expect(find_resource(work).visibility).to eq('authenticated')
      end

      it '"Yes please." copies the released visibility to the files, lifting their lease' do
        perform_enqueued_jobs { click_button 'Yes please.' }

        expect(page).to have_current_path(%r{\A/concern/generic_works/#{work.id}})
        expect(find_resource(file_set).visibility).to eq('authenticated')

        visit '/leases'
        within('#active') { expect(page).not_to have_content('Leased Member File') }
      end

      it '"No. I\'ll update it manually." leaves the file leases in place' do
        perform_enqueued_jobs { click_link "No. I'll update it manually." }

        expect(page).to have_current_path(%r{\A/concern/generic_works/#{work.id}})
        expect(find_resource(file_set).visibility).to eq('open')

        visit '/leases'
        within('#active') do
          expect(page).to have_link('Leased Member File')
          expect(page).not_to have_content('Leased Parent Work')
        end
      end
    end
  end
end
