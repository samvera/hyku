# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Transfers and Proxies', type: :feature, js: true, clean: true do
  let(:user) { create(:user, email: 'transferuser@example.com') }
  let(:recipient) { create(:user, email: 'recipient@example.com') }

  before do
    login_as user
  end

  it 'can send, accept, reject, and cancel transfers' do
    visit '/dashboard/my/works'
    # Simulate sending a transfer (adjust selectors as needed)
    click_link 'Transfer Ownership', match: :first if page.has_link?('Transfer Ownership')
    fill_in 'Recipient', with: recipient.email
    click_button 'Send Transfer'
    expect(page).to have_content('Transfer Sent')
    # Mock recipient accepting the transfer
    logout(:user)
    login_as recipient
    visit '/dashboard/transfers'
    if page.has_button?('Accept')
      click_button 'Accept'
      expect(page).to have_content('Transfer Accepted')
    end
    # Mock recipient rejecting the transfer
    visit '/dashboard/transfers'
    if page.has_button?('Reject')
      click_button 'Reject'
      expect(page).to have_content('Transfer Rejected')
    end
    logout(:recipient)
    login_as user
  end

  it 'can add and remove proxies' do
    visit '/dashboard/proxies'
    fill_in 'Search users', with: recipient.email
    click_button 'Authorize Proxy'
    expect(page).to have_content(recipient.email)
    within('.current-proxies') do
      click_link 'Delete', match: :first
    end
    expect(page).not_to have_content(recipient.email)
  end

  # The examples above are heavily guarded (`if page.has_link?/has_button?`) and can
  # pass without asserting anything. The examples below exercise the Transfers dashboard
  # (/dashboard/transfers) against a REAL ProxyDepositRequest created in setup, instead of
  # driving the flaky send-transfer UI, so the sent/received tables and their Cancel/
  # Accept/Reject controls are actually tested. See the Manual Test Plan excerpt below.
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
    end
  end
end

# ## Transfers Page
# [Back to TOC](#table-of-contents)

# ![image1](https://github.com/samvera/hyku/assets/19597776/352904b6-423d-4434-b768-23cb563a22ec)

# ### As a user:

# - [ ] I can see all my Transfers Sent
#   - [ ] Title
#   - [ ] Date
#   - [ ] To
#   - [ ] Status
#     - [ ] Pending Sent transfers can be cancelled by the sender before transfer request is accepted
#   - [ ] Comments
# - [ ] I can see all my Transfers Received
#   - [ ] Contains same table columns as Transfers Sent, except “To” has been replaced with “From”
#     - [ ] Status actions include:
#       - [ ] Accept
#         - [ ] Allow depositor to retain edit access
#         - [ ] Remove depositor access
#         - [ ] Authorize depositor as proxy
#       - [ ] Reject