# frozen_string_literal: true

require 'rails_helper'

# The order rides on the sequence of the term_ids[] fields, so what gets saved is
# whatever DOM the script leaves behind — nothing the server rendered can be checked
# instead.
RSpec.describe 'Reordering a vocabulary\'s terms', type: :feature, js: true, clean: true, ci: 'skip' do
  let(:user) { FactoryBot.create(:admin) }

  # Named per-run rather than fixed: a create! here has to be the only claim on the
  # source key, and a leftover row of the same name would take it first.
  let(:name) { "term_order_#{SecureRandom.hex(4)}" }
  let(:label) { "Reading Rooms #{name}" }

  let!(:vocabulary) do
    Qa::LocalAuthority.create!(name: name, label: label).tap do |authority|
      authority.local_authority_entries.create!(label: 'Alpha', uri: 'alpha')
      authority.local_authority_entries.create!(label: 'Beta', uri: 'beta')
      authority.local_authority_entries.create!(label: 'Gamma', uri: 'gamma')
    end
  end

  # Rendered rows, not the database, so an example can tell a move the script made
  # from one that was actually saved.
  def displayed_labels
    all('[data-term-row]').map { |row| row[:'data-term-label'] }
  end

  def stored_labels
    vocabulary.local_authority_entries.ordered.pluck(:label)
  end

  def move_button(label, direction)
    find("[data-term-row][data-term-label='#{label}'] [data-term-move='#{direction}']")
  end

  before do
    login_as user
    visit "/dashboard/controlled_vocabularies/#{name}"
  end

  it 'draws the terms in their stored order' do
    expect(displayed_labels).to eq %w[Alpha Beta Gamma]
  end

  describe 'the move buttons' do
    it 'moves a term down and saves the order' do
      move_button('Alpha', 1).click

      expect(displayed_labels).to eq %w[Beta Alpha Gamma]

      click_button 'Save order'

      expect(page).to have_content 'The term order was saved.'
      expect(stored_labels).to eq %w[Beta Alpha Gamma]
    end

    it 'moves a term up' do
      move_button('Gamma', -1).click

      expect(displayed_labels).to eq %w[Alpha Gamma Beta]
    end

    it 'refuses to move the first term earlier, and says so' do
      move_button('Alpha', -1).click

      expect(displayed_labels).to eq %w[Alpha Beta Gamma]
      expect(page).to have_selector('[data-term-order-status]', text: 'Alpha', visible: :all)
    end
  end

  # Dragging cannot be driven honestly through the driver; these run the same move()
  # it ends in.
  describe 'the arrow keys' do
    it 'moves a term with the down arrow from its handle' do
      find("[data-term-row][data-term-label='Alpha'] [data-term-handle]").send_keys(:arrow_down)

      expect(displayed_labels).to eq %w[Beta Alpha Gamma]
    end

    it 'moves a term with the up arrow' do
      find("[data-term-row][data-term-label='Gamma'] [data-term-move='1']").send_keys(:arrow_up)

      expect(displayed_labels).to eq %w[Alpha Gamma Beta]
    end

    it 'saves an order set entirely from the keyboard' do
      find("[data-term-row][data-term-label='Alpha'] [data-term-handle]").send_keys(:arrow_down)
      click_button 'Save order'

      expect(stored_labels).to eq %w[Beta Alpha Gamma]
    end
  end

  # Retiring submits one of the hidden per-term forms, not the reorder form, so it
  # would navigate away and take an unsaved order with it.
  describe 'the retire toggles while an order is unsaved' do
    let(:note) { I18n.t('hyku.admin.controlled_vocabulary.order_unsaved') }

    def toggles_marked_unavailable
      all('[data-term-status-toggle][aria-disabled="true"]').size
    end

    it 'leaves the toggles usable until something moves' do
      expect(toggles_marked_unavailable).to eq 0
      expect(page).to have_no_content(note)
    end

    it 'marks the toggles unavailable once a term moves' do
      move_button('Alpha', 1).click

      expect(toggles_marked_unavailable).to eq 3
    end

    # On the text, not the data attribute: matching the attribute found the form.
    it 'says why they are unavailable' do
      move_button('Alpha', 1).click

      expect(page).to have_content(note)
    end

    it 'keeps the toggles reachable by keyboard, unavailable rather than missing' do
      move_button('Alpha', 1).click

      expect(page).to have_button('Retire', disabled: false)
    end

    it 'refuses the retire it would otherwise submit' do
      move_button('Alpha', 1).click
      first('[data-term-status-toggle]').click

      expect(page).to have_content(note)
      expect(displayed_labels).to eq %w[Beta Alpha Gamma]
    end

    it 'offers them again once the order is saved' do
      move_button('Alpha', 1).click
      click_button 'Save order'

      expect(toggles_marked_unavailable).to eq 0
    end
  end

  # A restore replaces the table with a fresh node and fires turbolinks:load against
  # it, so the controls have to be bound to that new node.
  describe 'returning to a cached page' do
    it 'moves one position per press after going back to it' do
      within('.breadcrumb') { click_link 'Controlled Vocabularies' }
      expect(page).to have_link(label)

      page.go_back
      expect(page).to have_selector('[data-term-order-table]')

      move_button('Alpha', 1).click

      expect(displayed_labels).to eq %w[Beta Alpha Gamma]
    end
  end
end
