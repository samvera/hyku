# frozen_string_literal: true

RSpec.describe "hyrax/homepage/_home_text.html.erb", type: :view do
  subject { rendered }

  let(:groups) { [] }
  let(:ability) { instance_double("Ability") }
  let(:home_text) { ContentBlock.new(name: ContentBlock::NAME_REGISTRY[:home_text], value: home_text_value) }

  before do
    view.extend Hyrax::ContentBlockHelper
    assign(:home_text, home_text)
    allow(controller).to receive(:current_ability).and_return(ability)
    render
  end

  context "when there is an home_text" do
    let(:home_text_value) { "Let me tell you about our repository..." }

    it { is_expected.to have_content home_text_value }
    it { is_expected.not_to have_button("Edit") }
  end

  context "when there is no home_text" do
    let(:home_text_value) { "" }

    it { is_expected.not_to have_selector "#home_text" }
  end
end
