# frozen_string_literal: true
begin
  require 'rubocop/rake_task'

  desc 'Run style checker'
  RuboCop::RakeTask.new(:rubocop) do |task|
    task.requires << 'rubocop-rspec'
    task.fail_on_error = true
  end
# rubocop:disable Lint/SuppressedException
rescue LoadError
  # rubocop: enable Lint/SuppressedException
end
