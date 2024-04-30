# frozen_string_literal: true
RSpec.describe SortTitle, type: :model do
  describe "Alphabetical" do
    it "Titlecase title and remove 'The', 'And' and 'A'" do
      expect(SortTitle.new("THE APPLE").alphabetical).to eq "apple"
      expect(SortTitle.new("a apple").alphabetical).to eq "apple"
      expect(SortTitle.new("An apple").alphabetical).to eq "apple"
      expect(SortTitle.new("The A apple And An").alphabetical).to eq "a apple and an"
      expect(SortTitle.new("LS575 Course with no name").alphabetical).to eq "ls000575 course with no name"
    end
  end
end
