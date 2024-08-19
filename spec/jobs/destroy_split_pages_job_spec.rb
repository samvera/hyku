# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DestroySplitPagesJob do
  describe '#perform' do
    let(:work) do
      FactoryBot.valkyrie_create(:generic_work_resource, is_child: true)
    end

    it "deletes the work" do
      # When we raise an exception within a job, that exception is returned.
      result = described_class.perform_now(work.id.to_s)

      # Hence we need to check if we raised an exception within the job.
      expect(result).not_to be_a(Exception)

      # Assuming everything's working, we should no longer be able to find the work
      expect { Hyrax.query_service.find_by(id: work.id) }.to raise_error Valkyrie::Persistence::ObjectNotFoundError
    end
  end
end
