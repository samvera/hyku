require 'rails_helper'

RSpec.describe "pages/show", type: :view do
  let(:page) { FactoryGirl.create(:content_block, name: 'about_page', value: 'This is the page.') }

  before do
    assign(:page, page)
  end

  it "renders the about_page content block" do
    render
    expect(rendered).to include(page.value)
    expect(rendered).not_to include('tinymce') # Ensures sufia's view with editor is not rendered.
  end
end
