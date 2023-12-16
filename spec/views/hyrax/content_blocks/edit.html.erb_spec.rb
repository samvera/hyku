# frozen_string_literal: true

# Copied from Hyrax v2.9.0 to add home_text form - Adding themes
RSpec.describe "hyrax/content_blocks/edit", type: :view do
  before { render }
  # these first 3 tests are from hyrax
  it "renders the announcement form" do
    assert_select "form[action=?][method=?]", hyrax.content_block_path(ContentBlock.for(:announcement)), "post" do
      assert_select "textarea#content_block_announcement[name=?]", "content_block[announcement]"
    end
  end

  it "renders the marketing form" do
    assert_select "form[action=?][method=?]", hyrax.content_block_path(ContentBlock.for(:marketing)), "post" do
      assert_select "textarea#content_block_marketing[name=?]", "content_block[marketing]"
    end
  end

  it "renders the researcher form" do
    assert_select "form[action=?][method=?]", hyrax.content_block_path(ContentBlock.for(:researcher)), "post" do
      assert_select "textarea#content_block_researcher[name=?]", "content_block[researcher]"
    end
  end

  # Copied from Hyrax v2.9.0 to add home_text form - Adding themes
  it "renders the home_text_form" do
    assert_select "form[action=?][method=?]", hyrax.content_block_path(ContentBlock.for(:home_text)), "post" do
      assert_select "textarea#content_block_home_text[name=?]", "content_block[home_text]"
    end
  end

  it "loads the wysiwyg config file" do
    expect(rendered).to have_text('bold italic')
    # Checking to see if the changed tinymce.yml is changed in the scripts (we added hr).
    # This is no guarantee that it's actually loaded, that would be a full js integration test
  end

  it "renders the instruction blocks" do
    expect(rendered).to have_xpath('//p[@class="content-block-instructions" ]', count: 6)
  end

  # TODO: These next 4 tests are tightly coupled with the implimentation,
  # find a way to read the text from the yaml to test this
  it "renders the announcement instructions" do
    text = "Announcement Text displays on the homepage."
    expect(rendered).to have_xpath('//p[@class="content-block-instructions" ]', text:)
  end

  it "renders the banner instructions" do
    text = "Banner Text refers to the text that is displayed over banner image on the homepage."
    expect(rendered).to have_xpath('//p[@class="content-block-instructions" ]', text:)
  end

  it "renders the featured researcher instructions" do
    text = "Featured Researcher is a space to enter information and on"
    text += " the home page reserved for highlighting repository users."
    expect(rendered).to have_xpath('//p[@class="content-block-instructions" ]',
                                   text:)
  end

  # Copied from Hyrax v2.9.0 to add home_text form - Adding themes
  it "renders the home text instructions" do
    text = "Home Page Text refers to the custom messaging that is displayed"
    text += " on the home page either in the hero block or another section"
    text += " of the home page. This text appears when selecting a theme"
    text += " that either requires or allows home page text. We recommend"
    text += " no more than 3 sentences in this area."
    expect(rendered).to have_xpath('//p[@class="content-block-instructions" ]',
                                   text:)
  end
end
