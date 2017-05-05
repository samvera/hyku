# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

task default: [:rubocop, :ci]

Rails.application.load_tasks

begin
  SolrWrapper.default_instance_options = {
    verbose: Settings.solr_wrapper.verbose,
    cloud: Settings.solr_wrapper.cloud,
    port: Settings.solr_wrapper.port,
    version: Settings.solr_wrapper.version,
    instance_dir: Settings.solr_wrapper.instance_dir,
    download_dir: Settings.solr_wrapper.download_dir,
  }
  require 'solr_wrapper/rake_task'
rescue LoadError
end

task :ci do
  with_server 'test' do
    Rake::Task['spec'].invoke
  end
end
