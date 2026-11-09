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

    context 'when the work has file sets' do
      let(:work) do
        FactoryBot.valkyrie_create(:generic_work_resource, :with_member_file_sets, is_child: true)
      end

      it 'deletes the work and its file sets' do
        file_set_ids = work.member_ids

        described_class.perform_now(work.id.to_s)

        expect { Hyrax.query_service.find_by(id: work.id) }.to raise_error Valkyrie::Persistence::ObjectNotFoundError
        expect(Hyrax.query_service.find_many_by_ids(ids: file_set_ids).to_a).to be_empty
      end
    end

    context 'when the deletion fails' do
      let(:transaction) { double('work_resource.destroy') }

      before do
        allow(Hyrax::Transactions::Container).to receive(:[]).and_call_original
        allow(Hyrax::Transactions::Container).to receive(:[]).with('work_resource.destroy').and_return(transaction)
        allow(transaction).to receive(:with_step_args).and_return(transaction)
        allow(transaction).to receive(:call).and_return(Dry::Monads::Failure(:failed_to_delete_file_set))
      end

      it 'raises, so the job is retried' do
        expect { described_class.new.perform(work.id.to_s) }.to raise_error(Dry::Monads::UnwrapError)
      end
    end
  end
end
