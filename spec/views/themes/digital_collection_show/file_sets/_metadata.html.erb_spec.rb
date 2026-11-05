# frozen_string_literal: true

RSpec.describe 'themes/digital_collection_show/hyrax/file_sets/_metadata.html.erb', type: :view do
  let(:presenter) do
    double('file set', flexible?: false, license: ['http://creativecommons.org/publicdomain/mark/1.0/'], microdata_type_to_html: '')
  end

  before do
    allow(presenter).to receive(:display_values_for) { |field| field == :license ? ['Public Domain Mark 1.0'] : [] }
    without_partial_double_verification do
      allow(view).to receive(:compound_schema_for).and_return(Hyrax::CompoundSchema.new)
    end
    assign(:presenter, presenter)
    render partial: 'themes/digital_collection_show/hyrax/file_sets/metadata'
  end

  it "lists a file set's controlled values by their labels without flexible metadata" do
    expect(Capybara.string(rendered)).to have_css('dd', text: 'Public Domain Mark 1.0')
  end
end
