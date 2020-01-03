RSpec.shared_examples "work_form" do
  describe ".primary_terms" do
    it 'includes the license field' do
      expect(form.primary_terms).to include(:license)
    end
  end
end
