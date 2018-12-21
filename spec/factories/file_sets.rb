FactoryBot.define do
  factory :file_set do
    transient do
      user { FactoryBot.create(:user) }
    end
    after(:build) do |fs, evaluator|
      fs.apply_depositor_metadata evaluator.user
    end
  end
end
