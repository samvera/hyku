# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ImportCounterMetrics do
  # TODO: Write more robust tests for this service
  it 'creates Hyrax::CounterMetrics with investigations' do
    ImportCounterMetrics.import_investigations(Rails.root.join('spec', 'fixtures', 'csv', 'pittir-views.csv').to_s)
    expect(Hyrax::CounterMetric.count).not_to be_nil
  end

  it 'creates Hyrax::CounterMetrics with requests' do
    ImportCounterMetrics.import_requests(Rails.root.join('spec', 'fixtures', 'csv', 'pittir-views.csv').to_s)
    expect(Hyrax::CounterMetric.count).not_to be_nil
  end
end
