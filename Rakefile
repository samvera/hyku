# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

# Do not use fedora or solr wrappers in docker
# no reason to run those services locally twice
if ENV['IN_DOCKER']
  task default: [:rubocop, :spec]
else
  task default: [:rubocop, :ci]
end

Rails.application.load_tasks

begin
  require 'solr_wrapper/rake_task'
rescue LoadError
end

task :ci do
  with_server 'test' do
    Rake::Task['spec'].invoke
  end
end
