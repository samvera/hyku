FactoryBot.define do
  factory :group, class: Hyrax::Group do
    sequence(:name) { |_n| "group-#{srand}" }
    sequence(:description) { |_n| "Somthing about group-#{srand}" }
  end
end
