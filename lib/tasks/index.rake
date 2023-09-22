# frozen_string_literal: true

require 'ruby-progressbar'

desc "reindex just the works in the background"
task index_works: :environment do
  Account.find_each do |account|
    puts "=============== #{account.name}============"
    next if account.name == "search"
    switch!(account)
    in_each_account do
      ReindexWorksJob.perform_later
    end
  end
end

desc "reindex just the collections in the background"
task index_collections: :environment do
  Account.find_each do |account|
    puts "=============== #{account.name}============"
    next if account.name == "search"
    switch!(account)
    in_each_account do
      ReindexCollectionsJob.perform_later
    end
  end
end

desc "reindex just the admin_sets in the background"
task index_admin_sets: :environment do
  Account.find_each do |account|
    puts "=============== #{account.name}============"
    next if account.name == "search"
    switch!(account)
    in_each_account do
      ReindexAdminSetsJob.perform_later
    end
  end
end

desc "reindex just the file_sets in the background"
task index_file_sets: :environment do
  Account.find_each do |account|
    puts "=============== #{account.name}============"
    next if account.name == "search"
    switch!(account)
    in_each_account do
      ReindexFileSetsJob.perform_later
    end
  end
end

def in_each_account
  Account.find_each do |account|
    puts "=============== #{account.name}============"
    next if account.name == "search"
    switch!(account)
    yield
  end
end
