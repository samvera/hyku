# frozen_string_literal: true

RSpec.describe CreateDerivativesJob do
  around do |example|
    ffmpeg_enabled = Hyrax.config.enable_ffmpeg
    Hyrax.config.enable_ffmpeg = true
    example.run
    Hyrax.config.enable_ffmpeg = ffmpeg_enabled
  end

  describe 'recreating self as a CreateLargeDerivativesJob' do
    let(:id)       { '123' }
    let(:file_set) { FileSet.new }
    let(:file) do
      Hydra::PCDM::File.new.tap do |f|
        f.content = 'foo'
        f.original_name = filename
        f.save!
      end
    end

    before do
      allow(FileSet).to receive(:find).with(id).and_return(file_set)
      allow(file_set).to receive(:mime_type).and_return(mime_type)
      allow(file_set).to receive(:id).and_return(id)
      # Short-circuit irrelevant logic
      allow(file_set).to receive(:reload)
      allow(file_set).to receive(:update_index)
    end

    context 'with an image file' do
      let(:mime_type) { 'image/jpeg' }
      let(:filename) { 'picture.jpg' }

      before do
        # Short-circuit irrelevant logic
        allow(Hydra::Derivatives::ImageDerivatives).to receive(:create)
      end

      it 'does not recreate as a CreateLargeDerivativesJob' do
        expect(CreateLargeDerivativesJob).not_to receive(:perform_later)

        described_class.perform_now(file_set, file.id)
      end
    end

    context 'with an video file' do
      let(:mime_type) { 'video/mp4' }
      let(:filename) { 'video.mp4' }

      before do
        # Short-circuit irrelevant logic
        allow(Hydra::Derivatives::VideoDerivatives).to receive(:create)
      end

      it 'recreates as a CreateLargeDerivativesJob' do
        expect(CreateLargeDerivativesJob).to receive(:perform_later)

        described_class.perform_now(file_set, file.id)
      end
    end

    context 'with an audio file' do
      let(:mime_type) { 'audio/x-wav' }
      let(:filename) { 'audio.wav' }

      before do
        # Short-circuit irrelevant logic
        allow(Hydra::Derivatives::AudioDerivatives).to receive(:create)
      end

      it 'recreates as a CreateLargeDerivativesJob' do
        expect(CreateLargeDerivativesJob).to receive(:perform_later)

        described_class.perform_now(file_set, file.id)
      end
    end
  end
end
