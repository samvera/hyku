FactoryGirl.define do
  factory :account do
    sequence(:cname) { |_n| "#{srand}.example.com" }
    sequence(:tenant) { |_n| srand }
  end
end
