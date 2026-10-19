# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Transfers and Proxies', type: :feature, js: true, clean: true do
  let(:user) { create(:user, email: 'transferuser@example.com') }
  let(:recipient) { create(:user, email: 'recipient@example.com') }

  before do
    login_as user
  end

  # The proxy and transfer recipient pickers are select2 widgets that search users via
  # GET /users.json (Hyrax::UsersController#index). Hyku's UsersControllerDecorator applies
  # `authorize_resource class: '::User'` to the whole controller, so that search returns
  # 403 Forbidden unless the user may read Users (the user_manager/user_reader roles).
  # These examples run as a user_reader so the real UI flow can be exercised; the pending
  # example below documents that a regular user currently cannot use the pickers.
  context 'as a user permitted to search for other users (user_reader role)' do
    let(:user) { create(:user, email: 'transferuser@example.com', roles: [:user_reader]) }

    # Steps mirror Hyrax's own spec/features/ownership_transfer_spec.rb (work row actions ->
    # Transfer Ownership -> select2 recipient search -> comment -> Transfer).
    # Potential duplicate: spec/features/dashboard_my_works_spec.rb:161 (Transfer Ownership row action)
    it 'sends an ownership transfer request from the works dashboard' do
      work = create(:generic_work, user:, title: ['Work to transfer'])
      recipient # must exist before it can be searched for
      visit '/dashboard/my/works'

      within("#document_#{work.id}") { find('.dropdown-toggle').click }
      find('#action-transfer-work').click
      find('#s2id_proxy_deposit_request_transfer_to').click
      within('#select2-drop') { find('.select2-input').set(recipient.user_key) }
      within('#select2-drop') { find('.select2-result-selectable').click }
      fill_in 'proxy_deposit_request[sender_comment]', with: 'Please take this work'
      accept_confirm { click_button 'Transfer' }

      expect(page).to have_content('Transfer request created')
    end

    # Manage Proxies (/proxies). Steps mirror Hyrax's own spec/features/proxy_spec.rb.
    it 'can add and remove proxies' do
      recipient # must exist before it can be searched for
      visit '/proxies'
      # Help text and headings from hyrax/dashboard/_index_partials/_proxy_rights.
      within('.proxy-rights') do
        expect(page).to have_content('Select a user who can deposit works on your behalf. Both you and your ' \
                                     'proxy will be able to make changes to these works.')
        expect(page).to have_content('You can revoke a proxy by clicking the Delete Proxy button.')
        expect(page).to have_selector('h2', text: 'Authorize Proxies')
        expect(page).to have_selector('h2', text: 'Current Proxies')
      end
      expect(page).not_to have_css('td.depositor-name')

      find('a.select2-choice').click
      find('.select2-input').set(recipient.user_key)
      find('div.select2-result-label').click
      expect(page).to have_css('td.depositor-name', text: recipient.user_key)

      click_link 'Delete Proxy'
      # The page removes the row optimistically before the AJAX DELETE finishes, so wait
      # for the server-side deletion itself (bounded), then reload to confirm it persisted.
      Timeout.timeout(Capybara.default_max_wait_time) do
        sleep 0.1 while user.reload.can_receive_deposits_from.include?(recipient)
      end
      visit '/proxies'
      expect(page).not_to have_css('td.depositor-name', text: recipient.user_key)
    end
  end

  # Remove this comment and the `pending` call to re-enable this test when issue #3419 is fixed.
  # KNOWN APPLICATION ISSUE: a regular user's picker search (GET /users.json) is forbidden,
  # so they cannot find anyone to proxy or transfer to. This also breaks the transfer
  # recipient picker and the work Sharing tab user search for regular users.
  # Fix goes in: app/controllers/concerns/hyrax/users_controller_decorator.rb -- scope
  # `authorize_resource class: '::User'` so it does not apply to #index JSON search.
  # Once fixed, the user_reader context above can likely run as a regular user.
  # `pending` keeps this running: it fails loudly once the bug is fixed.
  # Potential duplicate: spec/features/work_new_form_spec.rb:188 (same /users.json 403 for regular users)
  it 'lets a regular user find another user in the Manage Proxies picker' do
    pending('Hyku UsersControllerDecorator authorizes Hyrax::UsersController#index, so ' \
            'GET /users.json returns 403 for users without the user_manager/user_reader role')
    recipient
    visit '/proxies'
    find('a.select2-choice').click
    find('.select2-input').set(recipient.user_key)

    expect(page).to have_css('div.select2-result-label', text: recipient.user_key)
  end

  # The examples below exercise the Transfers dashboard
  # (/dashboard/transfers) against a REAL ProxyDepositRequest created in setup, instead of
  # driving the flaky send-transfer UI, so the sent/received tables and their Cancel/
  # Accept/Reject controls are actually tested. Covers the Manual Test Plan's "Transfers Page".
  #
  # Grounding:
  # - ProxyDepositRequest model: sending_user/receiving_user/work_id/status/sender_comment,
  #   PENDING/CANCELED/REJECTED/ACCEPTED statuses (hyrax app/models/proxy_deposit_request.rb).
  # - Views hyrax/transfers/_sent.html.erb (table#outgoing-transfers, Cancel button_to) and
  #   _received.html.erb (table#incoming-transfers, Accept dropdown + Reject button_to).
  # - Controller hyrax/transfers_controller.rb notices: "Transfer canceled" (destroy),
  #   "Transfer rejected" (reject), "Transfer complete" (accept).
  context 'with a real pending ownership transfer request' do
    let!(:work) { create(:generic_work, user: user, title: ['Transfer Test Work']) }
    let!(:transfer_request) do
      ProxyDepositRequest.create!(
        work_id: work.id,
        sending_user: user,
        receiving_user: recipient,
        sender_comment: 'Please take ownership'
      )
    end

    it 'shows the sender a Transfers Sent list with Title, Date, recipient, Status and Comments' do
      visit '/dashboard/transfers'

      expect(page).to have_content('Transfers Sent')
      within('#outgoing-transfers') do
        %w[Title Date Status Comments].each do |heading|
          expect(page).to have_selector('th', text: heading)
        end
        # NOTE: hyrax labels this column "From" in both the sent and received tables
        # (both partials render t('.from')); for a sent transfer it holds the recipient
        # (the "To" party from the Manual Test Plan).
        # Update this assertion to expect "To" when issue #1816 is fixed. Fix goes in
        # Hyrax (samvera/hyrax): app/views/hyrax/transfers/_sent.html.erb.
        expect(page).to have_selector('th', text: 'From')
        expect(page).to have_link('Transfer Test Work')
        expect(page).to have_link(recipient.email)
        expect(page).to have_content('Please take ownership')
        # A pending sent transfer exposes a Cancel control to the sender.
        expect(page).to have_button('Cancel')
      end
    end

    it 'lets the sender cancel a pending sent transfer' do
      visit '/dashboard/transfers'

      within('#outgoing-transfers') do
        accept_confirm { click_button('Cancel') }
      end

      expect(page).to have_content('Transfer canceled')
      expect(transfer_request.reload.status).to eq('canceled')
    end

    it 'shows the recipient a Transfers Received list with a From column and Accept/Reject actions' do
      logout(:user)
      login_as recipient
      visit '/dashboard/transfers'

      expect(page).to have_content('Transfers Received')
      within('#incoming-transfers') do
        # Same columns as the sent table, with "From" holding the sending user.
        %w[Title Date From Status Comments].each do |heading|
          expect(page).to have_selector('th', text: heading)
        end
        expect(page).to have_link('Transfer Test Work')
        expect(page).to have_link(user.email)
        expect(page).to have_content('Please take ownership')
        # Status actions: Accept (a button opening a dropdown) and Reject.
        expect(page).to have_button('Accept')
        expect(page).to have_button('Reject')
        # The three Accept options live in a dropdown menu (hidden until opened). Assert
        # both their labels and that each targets the correct accept path/parameters:
        # retain -> no reset, remove -> reset=true, proxy -> sticky=true.
        expect(page).to have_link('Allow depositor to retain edit access',
                                  href: %r{/dashboard/transfers/#{transfer_request.id}/accept}, visible: :all)
        expect(page).to have_link('Remove depositor access',
                                  href: /accept\?.*reset=true/, visible: :all)
        expect(page).to have_link('Authorize depositor as proxy',
                                  href: /accept\?.*sticky=true/, visible: :all)
      end
    end

    it 'lets the recipient reject a received transfer' do
      logout(:user)
      login_as recipient
      visit '/dashboard/transfers'

      within('#incoming-transfers') do
        accept_confirm { click_button('Reject') }
      end

      expect(page).to have_content('Transfer rejected')
      expect(transfer_request.reload.status).to eq('rejected')
    end

    it 'lets the recipient accept a received transfer, retaining depositor edit access' do
      logout(:user)
      login_as recipient
      visit '/dashboard/transfers'

      within('#incoming-transfers') do
        find('button.dropdown-toggle.accept').click
        click_link('Allow depositor to retain edit access')
      end

      expect(page).to have_content('Transfer complete')
      expect(transfer_request.reload.status).to eq('accepted')
      transferred = Hyrax.query_service.find_by(id: work.id)
      expect(transferred.depositor).to eq(recipient.user_key)
      expect(transferred.permission_manager.edit_users.to_a).to contain_exactly(user.user_key, recipient.user_key)
      expect(recipient.reload.can_receive_deposits_from).to be_empty
    end

    # "Remove depositor access" passes reset=true, so Hyrax::ChangeDepositorService clears
    # the work's previous permissions before granting the recipient edit access.
    it 'lets the recipient accept a transfer and remove the depositor\'s access' do
      expect(Hyrax.query_service.find_by(id: work.id).permission_manager.edit_users.to_a).to include(user.user_key)
      logout(:user)
      login_as recipient
      visit '/dashboard/transfers'

      within('#incoming-transfers') do
        find('button.dropdown-toggle.accept').click
        click_link('Remove depositor access')
      end

      expect(page).to have_content('Transfer complete')
      expect(transfer_request.reload.status).to eq('accepted')
      transferred = Hyrax.query_service.find_by(id: work.id)
      expect(transferred.depositor).to eq(recipient.user_key)
      expect(transferred.permission_manager.edit_users.to_a).to eq([recipient.user_key])
    end

    # "Authorize depositor as proxy" passes sticky=true, so the recipient also authorizes the
    # sender to deposit on their behalf (Hyrax::TransfersController#accept).
    it 'lets the recipient accept a transfer and authorize the depositor as a proxy' do
      expect(recipient.can_receive_deposits_from).not_to include(user)
      logout(:user)
      login_as recipient
      visit '/dashboard/transfers'

      within('#incoming-transfers') do
        find('button.dropdown-toggle.accept').click
        click_link('Authorize depositor as proxy')
      end

      expect(page).to have_content('Transfer complete')
      expect(transfer_request.reload.status).to eq('accepted')
      expect(Hyrax.query_service.find_by(id: work.id).depositor).to eq(recipient.user_key)
      expect(recipient.reload.can_receive_deposits_from).to contain_exactly(user)
      expect(user.reload.can_make_deposits_for).to contain_exactly(recipient)
    end
  end
end
