RSpec.describe UniversalViewer do
  subject { described_class.instance }

  describe "#viewer_version" do
    it "calculates it from existing directories" do
      expect(subject.viewer_version).to eq "2.0.1"
    end
  end
  describe "#viewer_link" do
    it "is a relative link to the viewer" do
      expect(subject.viewer_link).to eq "/#{subject.viewer_root}/uv-2.0.1/lib/embed.js"
    end
  end

  describe "#script_tag" do
    it "is html safe" do
      expect(subject.script_tag).to be_html_safe
    end
  end
end
