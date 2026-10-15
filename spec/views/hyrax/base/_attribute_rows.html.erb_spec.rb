# frozen_string_literal: true

RSpec.describe 'hyrax/base/_attribute_rows.html.erb', type: :view do
  let(:presenter) do
    double('presenter', editor?: false, flexible?: true, creator: [], admin_note_field: [], hidden_field: [], subject: [], item_id: [], access_right: [])
  end
  let(:profile) do
    {
      creator: { 'display_label' => { 'es' => 'Autoría', 'default' => 'Creator' }, 'html_dl' => true },
      admin_note_field: { 'admin_only' => true, 'html_dl' => true },
      hidden_field: { 'show_page' => false, 'html_dl' => true },
      subject: { 'html_dl' => true },
      item_id: { 'display_label' => { 'default' => 'Item ID' }, 'html_dl' => true },
      access_right: { 'display_label' => { 'default' => 'Access Right' }, 'html_dl' => true }
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

  it "keeps a profile's plain-text label as written when Hyku has no translation for it" do
    expect(terms['item_id']).to eq('Item ID')
  end

  it "prefers Hyku's translated label over a plain-text profile label" do
    expect(I18n.with_locale(:es) { terms }['access_right']).to eq('Derechos de acceso')
  end

  it 'leaves out fields the profile hides from the show page or keeps for admins' do
    expect(terms.keys).to contain_exactly('creator', 'subject', 'item_id', 'access_right')
  end
end
