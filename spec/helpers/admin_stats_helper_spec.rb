RSpec.describe AdminStatsHelper do
  describe "#graph_tag" do
    let(:data) { [{ "label" => "foo", "data" => 7 }] }
    subject { helper.graph_tag('work', data, {}) }

    let(:node) { Capybara::Node::Simple.new(subject) }

    it 'draws html' do
      expect(node).to have_selector '.graph-container > #work'
      expect(node.find('.graph-container')['data-graph-data']).to eq "[{\"label\":\"foo\",\"data\":7}]"
    end
  end
end
