# frozen_string_literal: true

FactoryBot.define do
  factory :domain_name do
    sequence(:cname) { |_n| srand }
  end
end
