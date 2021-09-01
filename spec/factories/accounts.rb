# frozen_string_literal: true

FactoryBot.define do
  factory :solr_endpoint do
    options { Hash.new(url: 'http://fakesolr.localhost:9876/solr/', collection: 'fakecore') }
  end
  factory :fcrepo_endpoint do
    options { Hash.new(url: 'http://fakefedora.localhost:8765/', base_path: 'fakebase') }
  end
  factory :redis_endpoint do
    options { Hash.new(namespace: 'fakeNS') }
  end

  factory :account do
    sequence(:name) { |_n| srand }

    solr_endpoint
    redis_endpoint
    fcrepo_endpoint

    transient do
      domain_names_count { 1 }
    end
    after(:create) do |account, evaluator|
      create_list(:domain_name, evaluator.domain_names_count, account: account)
    end

    trait(:public_schema) do
      tenant { 'public' }
    end

    factory :account_with_public_schema, traits: [:public_schema]
  end

  factory :sign_up_account, class: Account do
    sequence(:name) { |_n| srand }

    transient do
      domain_names_count { 1 }
    end
    after(:create) do |account, evaluator|
      create_list(:domain_name, evaluator.domain_names_count, account: account)
    end
  end
end
