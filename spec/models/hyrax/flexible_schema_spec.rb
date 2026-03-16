# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyrax::FlexibleSchema, type: :model do
  it 'has a valid .current_schema' do
    described_class.create_default_schema

    # The existence of a non-nil ID is pressumed to ensure that a valid schema was loaded
    expect(described_class.current_schema_id).to be_present
  end
end
