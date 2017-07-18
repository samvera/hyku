FactoryGirl.define do
  factory :generic_work, aliases: [:work] do
    transient do
      user { FactoryGirl.create(:user) }
    end

    title ["Test title"]

    factory :work_with_one_file do
      before(:create) do |work, evaluator|
        work.ordered_members << FactoryGirl.create(:file_set, user: evaluator.user, title: ['A Contained Generic File'], label: 'test label')
      end
    end

    after(:build) do |work, evaluator|
      work.apply_depositor_metadata(evaluator.user)
    end
  end
end
