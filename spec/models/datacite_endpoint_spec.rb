# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DataCiteEndpoint do
  it { should have_one(:account).with_foreign_key(:data_cite_endpoint_id) }
end
