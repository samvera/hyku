# frozen_string_literal: true

require 'fileutils'

namespace :hyku do
  namespace :upgrade do
    desc 'Clean up migration duplications between new hyrax migrations and existing migrations'
    task 'clean_migrations', [:datestub] => [:environment] do |_cmd, args|
      unless args.datestub
        error_message = <<-MESSAGE
          Requires a partial date match that is the date that `hyrax:install:migrations`
          was run like `rails hyku:upgrade:clean_migrations[20180524]`
        MESSAGE
        raise ArgumentError, error_message
      end
      Dir.chdir(Rails.root.join('db', 'migrate')) do
        Dir.glob("#{args.datestub}*") do |file|
          core = file.split(".")[0].split("_")[1..-1].join("_")
          matches = Dir.glob("*#{core}.rb") +
                    Dir.glob("*#{core}.blacklight.rb") +
                    Dir.glob("*#{core}.sufia.rb") +
                    Dir.glob("*#{core}.curation_concerns.rb")

          if matches.present?
            FileUtils.rm(file)
            puts "Removed: #{file}"
          end
        end
      end
    end
  end
end
