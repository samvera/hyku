# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyrax::IiifAv::DisplaysContentDecorator do
  # We're prepending the DisplaysContentDecorator to the Hyrax::IiifAv::DisplaysContent
  describe Hyrax::IiifAv::DisplaysContent do
    describe '.public_instance_methods' do
      subject { Hyrax::IiifAv::DisplaysContent.public_instance_methods }

      it { is_expected.to include(:solr_document) }
      it { is_expected.to include(:current_ability) }
    end
  end
end
