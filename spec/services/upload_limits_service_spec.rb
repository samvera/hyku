# frozen_string_literal: true

RSpec.describe UploadLimitsService do
  let(:account) { build(:account, settings:) }
  let(:settings) { {} }

  before { allow(Site).to receive(:account).and_return(account) }

  describe '.file_size_error' do
    context 'when no tenant account is present' do
      let(:account) { nil }

      it 'returns nil' do
        expect(described_class.file_size_error(size: 10)).to be_nil
      end
    end

    context 'when the size is within the tenant limit' do
      let(:settings) { { file_size_limit: '100' } }

      it 'returns nil' do
        expect(described_class.file_size_error(size: 100)).to be_nil
      end
    end

    context 'when the size exceeds the tenant limit' do
      let(:settings) { { file_size_limit: '100' } }

      it 'returns a translated message naming the file and the limit' do
        message = described_class.file_size_error(size: 101, filename: 'big.tif')

        expect(message).to include('big.tif')
        expect(message).to include('100 Bytes')
      end
    end
  end

  describe '.content_type_error' do
    context 'when no allowed content types are configured' do
      it 'returns nil for any content type' do
        expect(described_class.content_type_error(content_type: 'video/mp4')).to be_nil
      end
    end

    context 'when the content type is in the allowed list' do
      let(:settings) { { allowed_content_types: 'image/png, application/pdf' } }

      it 'returns nil' do
        expect(described_class.content_type_error(content_type: 'application/pdf')).to be_nil
      end

      it 'matches case insensitively' do
        expect(described_class.content_type_error(content_type: 'Image/PNG')).to be_nil
      end
    end

    context 'when a wildcard subtype is configured' do
      let(:settings) { { allowed_content_types: 'image/*' } }

      it 'returns nil for any subtype of the wildcard' do
        expect(described_class.content_type_error(content_type: 'image/jpeg')).to be_nil
      end

      it 'returns a message for other types' do
        expect(described_class.content_type_error(content_type: 'video/mp4')).to be_present
      end
    end

    context 'when the content type is not in the allowed list' do
      let(:settings) { { allowed_content_types: 'image/png' } }

      it 'returns a translated message naming the type and the allowed types' do
        message = described_class.content_type_error(content_type: 'video/mp4', filename: 'movie.mp4')

        expect(message).to include('video/mp4')
        expect(message).to include('image/png')
        expect(message).to include('movie.mp4')
      end

      it 'returns a message when the content type is unknown' do
        expect(described_class.content_type_error(content_type: nil)).to be_present
      end
    end
  end

  describe '.storage_error' do
    let(:solr_response) do
      { 'stats' => { 'stats_fields' => { 'file_size_lts' => { 'sum' => 5000.0 } } } }
    end

    before { allow(Hyrax::SolrService).to receive(:get).and_return(solr_response) }

    context 'when no storage limit is configured' do
      it 'returns nil without querying Solr' do
        expect(described_class.storage_error(additional_bytes: 10)).to be_nil
        expect(Hyrax::SolrService).not_to have_received(:get)
      end
    end

    context 'when the new bytes fit under the ceiling' do
      let(:settings) { { storage_limit: '10240' } }

      it 'returns nil' do
        expect(described_class.storage_error(additional_bytes: 5240)).to be_nil
      end
    end

    context 'when the new bytes would cross the ceiling' do
      let(:settings) { { storage_limit: '10240' } }

      it 'returns a translated message naming the limit' do
        message = described_class.storage_error(additional_bytes: 5241)

        expect(message).to include('storage limit')
        expect(message).to include('10 KB')
      end
    end
  end

  describe '.current_storage_usage' do
    it 'sums the file sizes indexed on the tenant FileSets' do
      allow(Hyrax::SolrService).to receive(:get)
        .with('has_model_ssim:FileSet', rows: 0, stats: true, 'stats.field' => 'file_size_lts')
        .and_return('stats' => { 'stats_fields' => { 'file_size_lts' => { 'sum' => 12_345.0 } } })

      expect(described_class.current_storage_usage).to eq(12_345)
    end

    it 'returns zero when Solr reports no statistics' do
      allow(Hyrax::SolrService).to receive(:get).and_return({})

      expect(described_class.current_storage_usage).to eq(0)
    end
  end
end
