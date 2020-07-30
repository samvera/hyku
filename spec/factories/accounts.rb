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
    sequence(:cname) { |_n| srand }
    solr_endpoint
    redis_endpoint
    fcrepo_endpoint
  end
  factory :sign_up_account, class: Account do
    sequence(:name) { |_n| srand }
  end
end
