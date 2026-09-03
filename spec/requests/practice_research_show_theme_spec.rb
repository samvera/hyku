# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'practice_research_show theme', type: :request, singletenant: true, clean_repo: true do
  include Devise::Test::IntegrationHelpers

  let(:admin) { FactoryBot.create(:admin) }
  let(:file_set) { valkyrie_create(:hyrax_file_set, title: ['Bound portfolio.pdf'], visibility_setting: 'open') }
  let(:child_work) { indexed(GenericWorkResource.new(title: ['A Machine for Learning'])) }
  let(:parent) { indexed(GenericWorkResource.new(title: ['Primary Space'], member_ids: [file_set.id, child_work.id])) }

  def indexed(resource)
    saved = Hyrax.persister.save(resource:)
    Hyrax.index_adapter.save(resource: saved)
    saved
  end

  before do
    Hyrax::Group.create(name: 'admin')
    sign_in admin
    allow_any_instance_of(ApplicationController).to receive(:show_page_theme).and_return('practice_research_show')
  end

  it 'renders the theme, with files and child works in separate sections' do
    get "/concern/generic_works/#{parent.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('pr-show')
    expect(response.body).to include('Primary Space')

    doc = Nokogiri::HTML(response.body)
    files_pane = doc.at_css('#pr-pane-files').text
    items_pane = doc.at_css('#pr-pane-items').text

    expect(files_pane).to include('Bound portfolio.pdf')
    expect(files_pane).not_to include('A Machine for Learning')
    expect(items_pane).to include('A Machine for Learning')
    expect(items_pane).not_to include('Bound portfolio.pdf')
  end

  it 'lists an unreadable child work without exposing its description' do
    restricted = indexed(
      GenericWorkResource.new(title: ['Private Child'], description: ['SECRET DESCRIPTION BODY'])
    )
    parent = indexed(GenericWorkResource.new(title: ['Has a private child'], member_ids: [restricted.id]))

    allow_any_instance_of(::Ability).to receive(:can?).and_wrap_original do |original, action, subject|
      id = subject.respond_to?(:id) ? subject.id : subject
      action == :read && id.to_s == restricted.id.to_s ? false : original.call(action, subject)
    end

    get "/concern/generic_works/#{parent.id}"

    expect(response).to have_http_status(:ok)

    items = Nokogiri::HTML(response.body).at_css('#pr-pane-items')
    expect(items.at_css('.pr-item-title').text.strip).to eq('Private')
    expect(items.text).not_to include('SECRET DESCRIPTION BODY')
  end

  it 'drops the files tab when the record holds no files of its own' do
    work_without_files = indexed(GenericWorkResource.new(title: ['Empty of files'], member_ids: [child_work.id]))

    get "/concern/generic_works/#{work_without_files.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include('id="pr-pane-files"')
    expect(response.body).to include('id="pr-pane-items"')
  end
end
