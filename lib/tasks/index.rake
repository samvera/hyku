# frozen_string_literal: true

require 'ruby-progressbar'

require 'ruby-progressbar'

namespace :hyku do
  desc "reindex just the works in the background"
  task reindex_works: :environment do
    Account.find_each do |account|
      puts "=============== #{account.name}============"
      next if account.name == "search"
      switch!(account)
      begin
        Site.instance.available_works.each do |work_type|
          title = "~ #{account.name} - #{work_type}"
          klass = work_type.constantize
          progressbar = ProgressBar.create(total: klass.count, title: title, format: "%t %c of %C %a %B %p%%")
          klass.find_each do |w|
            ReindexWorksJob.perform_later(w)
            progressbar.increment
          end
        end
      rescue => e
        puts "(#{e.message})"
      end
    end
  end

  desc "reindex just the collections in the background"
  task reindex_collections: :environment do
    Account.find_each do |account|
      puts "=============== #{account.name}============"
      next if account.name == "search"
      switch!(account)
      title = "~ #{account.name}"
      progressbar = ProgressBar.create(total: Collection.count, title: title, format: "%t %c of %C %a %B %p%%")
      begin
        Collection.find_each do |collection|
          ReindexCollectionsJob.perform_later(collection)
          progressbar.increment
        end
      rescue => e
        puts "(#{e.message})"
      end
    end
  end

  desc "reindex just the filesets in the background"
  task reindex_filesets: :environment do
    Account.find_each do |account|
      puts "=============== #{account.name}============"
      next if account.name == "search"
      switch!(account)
      title = "~ #{account.name}"
      progressbar = ProgressBar.create(total: FileSet.count, title: title, format: "%t %c of %C %a %B %p%%")
      begin
        FileSet.find_each do |file_set|
          FileSetIndexJob.perform_later(file_set)
          progressbar.increment
        end
      rescue => e
        puts "(#{e.message})"
      end
    end
  end
end
