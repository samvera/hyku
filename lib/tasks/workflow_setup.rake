# frozen_string_literal: true
namespace :workflow do
  desc 'Load new workflow so it is available to existing admin sets'
  task setup: :environment do
    Hyrax::Workflow::WorkflowImporter.load_workflows
  end
end
