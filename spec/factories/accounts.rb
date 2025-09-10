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
  factory :data_cite_endpoint do
    options { Hash.new(mode: 'test', prefix: '10.1234', username: 'user123', password: 'pass123') }
  end

  factory :account do
    sequence(:name) { |_n| srand }

    solr_endpoint
    redis_endpoint
    fcrepo_endpoint
    data_cite_endpoint

    settings do
      {
        contact_email: 'abc@abc.com',
        weekly_email_list: ["aaa@aaa.com", "bbb@bl.uk"],
        monthly_email_list: ["aaa@aaa.com", "bbb@bl.uk"],
        yearly_email_list: ["aaa@aaa.com", "bbb@bl.uk"],
        google_scholarly_work_types: ['Article', 'Book', 'ThesisOrDissertation', 'BookChapter'],
        gtm_id: "GTM-123456", shared_login: "true",
        email_format: ["@pacificu.edu", "@ubiquitypress.com", "@test.com"],
        allow_signup: "true",
        google_analytics_id: 'G-1234567890',
        google_analytics_property_id: '123456789',
        geonames_username: 'geonames'
      }
    end

    transient do
      domain_names_count { 1 }
    end
    after(:create) do |account, evaluator|
      create_list(:domain_name, evaluator.domain_names_count, account:)
    end

    trait(:public_schema) do
      tenant { 'public' }
    end

    trait(:search_only) do
      search_only { true }
    end

    factory :search_only_account, traits: [:search_only]
    factory :account_with_public_schema, traits: [:public_schema]
  end

  factory :sign_up_account, class: Account do
    sequence(:name) { |_n| srand }

    transient do
      domain_names_count { 1 }
    end
    after(:create) do |account, evaluator|
      create_list(:domain_name, evaluator.domain_names_count, account:)
    end
  end
end
