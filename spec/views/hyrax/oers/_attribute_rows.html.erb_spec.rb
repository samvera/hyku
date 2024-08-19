# frozen_string_literal: true
RSpec.describe 'hyrax/oers/_attributes.html.erb' do
  let(:creator)     { 'Bilbo' }
  let(:contributor) { 'Frodo' }
  let(:subject)     { 'history' }
  let(:description) { ['Lorem ipsum < lorem ipsum. http://my.link.com'] }
  let(:date_created) { 'October 3, 2000' }
  let(:alternative_title) { 'alternative_title' }
  let(:table_of_contents) { 'table of contents' }
  let(:additional_information) { 'additional information' }
  let(:rights_holder) { 'rights holder' }
  let(:size) { '3 feet' }
  let(:accessibility_feature) { 'Alternative Text' }
  let(:accessibility_hazard) { 'Flashing' }
  let(:accessibility_summary) { 'Summary' }
  let(:audience) { 'Instructor' }
  let(:education_level) { 'College / Upper division' }
  let(:learning_resource) { 'Game' }
  let(:discipline) { 'Computing and Information - Computer Science' }
  let(:publisher) { 'Penguin' }
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:attributes) do
    {
      has_model_ssim: ["Oer"],
      subject_tesim: subject,
      contributor_tesim: contributor,
      creator_tesim: creator,
      description_tesim: description,
      date_created_tesim: date_created,
      alternative_title_tesim: alternative_title,
      table_of_contents_tesim: table_of_contents,
      additional_information_tesim: additional_information,
      rights_holder_tesim: rights_holder,
      oer_size_tesim: size,
      publisher_tesim: publisher,
      accessibility_feature_tesim: accessibility_feature,
      accessibility_hazard_tesim: accessibility_hazard,
      accessibility_summary_tesim: accessibility_summary,
      audience_tesim: audience,
      education_level_tesim: education_level,
      learning_resource_type_tesim: learning_resource,
      discipline_tesim: discipline
    }
  end
  let(:ability) { double(admin?: true) }
  let(:presenter) do
    Hyrax::OerPresenter.new(solr_document, ability)
  end
  let(:doc) { Nokogiri::HTML(rendered) }

  before do
    allow(presenter).to receive(:member_of_collection_presenters).and_return([])
    allow(view).to receive(:dom_class).and_return('')
    allow(presenter).to receive(:editor?).and_return(true)
    render 'hyrax/oers/attribute_rows', presenter:
  end

  # rubocop:disable RSpec/ExampleLength
  it 'has links to search for other objects with the same metadata' do
    expect(rendered).to have_css('li.attribute-alternative_title', text: alternative_title)
    expect(rendered).to have_link(creator)
    expect(rendered).to have_link(contributor)
    expect(rendered).to have_link(learning_resource)
    expect(rendered).to have_link(education_level)
    expect(rendered).to have_link(audience)
    expect(rendered).to have_link(discipline)
    expect(rendered).to have_css('li.attribute-date_created', text: 'October 3, 2000')
    expect(rendered).to have_css('li.attribute-table_of_contents', text: table_of_contents)
    expect(rendered).to have_link(subject)
    expect(rendered).to have_link(rights_holder)
    expect(rendered).to have_css('li.attribute-oer_size', text: size)
    expect(rendered).to have_link(publisher)
    expect(rendered).to have_link(accessibility_feature)
    expect(rendered).to have_link(accessibility_hazard)
    expect(rendered).to have_link(accessibility_summary)
    expect(rendered).to have_link(discipline)
  end
  # rubocop:enable RSpec/ExampleLength
end
