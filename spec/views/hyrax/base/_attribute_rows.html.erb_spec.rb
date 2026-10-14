# frozen_string_literal: true

RSpec.describe 'hyrax/base/_attribute_rows.html.erb', type: :view do
  let(:presenter) { double('presenter', editor?: false) }
  let(:profile) do
    {
      creator: { 'display_label' => { 'es' => 'Autoría', 'default' => 'Creator' }, 'html_dl' => true },
      admin_note_field: { 'admin_only' => true, 'html_dl' => true },
      hidden_field: { 'show_page' => false, 'html_dl' => true },
      subject: { 'html_dl' => true }
    }
  end

  before do
    allow(Hyrax.config).to receive(:flexible?).and_return(true)
    allow(view).to receive(:view_options_for).with(presenter).and_return(profile)
    allow(view).to receive(:compound_card_field?).and_return(false)
    allow(view).to receive(:current_user).and_return(nil)
    allow(presenter).to receive(:attribute_to_html) { |field, options| view.tag.dt(options[:label], data: { field: }) }
  end

  def terms
    render 'hyrax/base/attribute_rows', presenter: presenter
    Nokogiri::HTML(rendered).css('dt').to_h { |dt| [dt['data-field'], dt.text] }
  end

  it "uses the profile's label for the current language" do
    expect(I18n.with_locale(:es) { terms }['creator']).to eq('Autoría')
  end

  it 'leaves out fields the profile hides from the show page or keeps for admins' do
    expect(terms.keys).to contain_exactly('creator', 'subject')
  end
end
