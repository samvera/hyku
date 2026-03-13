# frozen_string_literal: true

RSpec.describe CreateLargeDerivativesJob, type: :job do
  before do
    ActiveJob::Base.queue_adapter = :test
    allow(FileSet).to receive(:find).with(id).and_return(file_set)
    allow(file_set).to receive(:id).and_return(id)
    # Short-circuit irrelevant logic
    allow(file_set).to receive(:reload)
    allow(file_set).to receive(:update_index)
  end

  after do
    clear_enqueued_jobs
  end

  let(:id)       { '123' }
  let(:file_set) { FileSet.new }
  let(:file) do
    Hydra::PCDM::File.new.tap do |f|
      f.content = 'foo'
      f.original_name = 'video.mp4'
      f.save!
    end
  end

  it 'runs in the :auxiliary queue' do
    expect { described_class.perform_later(file_set, file.id) }
      .to have_enqueued_job(described_class)
      .on_queue('auxiliary')
  end

  # @see CreateDerivativesJobDecorator#perform
  it "doesn't schedule itself infinitly" do
    expect(described_class).not_to receive(:perform_later)

    described_class.perform_now(file_set, file.id)
  end

  it 'successfully calls the logic in CreateDerivativesJob' do
    allow(file_set).to receive(:mime_type).and_return('video/mp4')
    expect(Hydra::Derivatives::VideoDerivatives).to receive(:create)

    described_class.perform_now(file_set, file.id)
  end
end
