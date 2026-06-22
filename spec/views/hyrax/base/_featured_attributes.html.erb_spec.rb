# frozen_string_literal: true

# Covers the featured-attribute rendering extracted from _work_title into its own
# partial: a property flagged `view: { position: featured }` renders prominently
# above the metadata table as sanitized HTML, disallowed tags are stripped, and
# non-featured or blank fields render nothing.
RSpec.describe 'hyrax/base/featured_attributes', type: :view do
  let(:user) { FactoryBot.create(:user) }
  let(:ability) { Ability.new(user) }
  let(:presenter) { Hyku::WorkShowPresenter.new(SolrDocument.new, ability) }
  let(:page) { Capybara::Node::Simple.new(rendered) }

  before do
    # conform_field maps a (possibly flexible) field to the presenter method name;
    # for these specs the field name is the method name.
    allow(view).to receive(:conform_field) { |field, _opts| field }
  end

  context 'with a field flagged view: { position: featured }' do
    before do
      allow(view).to receive(:view_options_for).with(presenter)
        .and_return('context_narrative' => { 'position' => 'featured', 'render_as' => 'html' })
      allow(presenter).to receive(:context_narrative)
        .and_return('<p>Featured <strong>narrative</strong></p><script>alert(1)</script>')
    end

    it 'renders the value as sanitized HTML, stripping disallowed tags' do
      render 'hyrax/base/featured_attributes', presenter: presenter

      expect(page).to have_css('section.work-featured-attribute.attribute-context_narrative strong', text: 'narrative')
      expect(rendered).to include('<strong>narrative</strong>')
      expect(rendered).not_to include('<script>')
    end
  end

  context 'when no field is flagged featured' do
    before do
      allow(view).to receive(:view_options_for).with(presenter)
        .and_return('title' => { 'position' => 'inline' })
      allow(presenter).to receive(:title).and_return(['A title'])
    end

    it 'renders nothing' do
      render 'hyrax/base/featured_attributes', presenter: presenter

      expect(rendered.strip).to be_blank
    end
  end

  context 'when the featured field is blank' do
    before do
      allow(view).to receive(:view_options_for).with(presenter)
        .and_return('context_narrative' => { 'position' => 'featured' })
      allow(presenter).to receive(:context_narrative).and_return('')
    end

    it 'does not render an empty featured section' do
      render 'hyrax/base/featured_attributes', presenter: presenter

      expect(page).not_to have_css('section.work-featured-attribute')
    end
  end
end
