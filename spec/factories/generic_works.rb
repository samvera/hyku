# frozen_string_literal: true

FactoryBot.define do
  factory :generic_work, aliases: [:work] do
    transient do
      user { FactoryBot.create(:user) }
    end

    title { ["Test title"] }

    identifier do
      %w[
        ISBN:978-83-7659-303-6 978-3-540-49698-4 9790879392788
        doi:10.1038/nphys1170 3-921099-34-X 3-540-49698-x 0-19-852663-6
      ]
    end

    factory :work_with_one_file do
      before(:create) do |work, evaluator|
        work.ordered_members << FactoryBot.create(:file_set,
                                                  user: evaluator.user,
                                                  title: ['A Contained Generic File'])
      end
    end

    after(:build) do |work, evaluator|
      work.apply_depositor_metadata(evaluator.user)
    end
  end
end
