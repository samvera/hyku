# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NilDataCiteEndpoint do
  describe '#switch!' do
    # Why test this?  Because the underlying datacite gem does not work with Hyrax 3.  And it would
    # be useful to demonstrate that switch! for a nil endpoint doesn't raise an exception.
    it 'does not raise an exception' do
      expect { described_class.new.switch! }.not_to raise_error
    end
  end
end
