# frozen_string_literal: true
FactoryBot.define do
  factory :oer, aliases: [:oer_work] do
    transient do
      user { FactoryBot.create(:user) }
    end

    title { ["OER title"] }
    audience { ["Student"] }
    education_level { ["Community college / Lower division"] }
    learning_resource_type { ["Supplemental audio/video"] }
    resource_type { ["InteractiveResource"] }
    discipline { ["Arts and Humanities - Classics"] }

    factory :oer_work_with_one_file do
      before(:create) do |work, evaluator|
        work.ordered_members << FactoryBot.create(:file_set,
                                                  user: evaluator.user,
                                                  title: ['A Sample OER File'])
      end
    end

    factory :oer_with_file_and_work do
      before(:create) do |work, evaluator|
        work.ordered_members << create(:file_set, user: evaluator.user)
        work.ordered_members << create(:oer_work, user: evaluator.user)
      end
    end

    factory :oer_with_previous_version do
      before(:create) do |work, evaluator|
        work.previous_version << create(:oer_work, user: evaluator.user)
      end
    end

    after(:build) do |work, evaluator|
      work.apply_depositor_metadata(evaluator.user)
    end
  end
end
