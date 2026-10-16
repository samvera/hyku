# frozen_string_literal: true

# Much of this testing is the complex configurable stuff underneath UploadedFile
# and simulating the AWS configuration that would be in production.

# rubocop:disable Layout/LineLength
RSpec.describe 'Hyrax::UploadedFile' do # rubocop:disable RSpec/DescribeClass
  let(:file) { File.open(file_fixture_path + '/images/world.png') }
  let(:upload) { Hyrax::UploadedFile.create(file:) }
  let(:config) { CarrierWave.configure { |c| c } }
  let(:bucket_name) { 'hyku-carrierwave-test' }
  let(:bigurl) { 'https://demo-application-w5twjcsuyx3v-uploadbucket-4l1zpvmp62nf.s3.amazonaws.com//var/app/current/public/uploads/hyrax/uploaded_file/file/31/image.png?X-Amz-Expires=600\u0026X-Amz-Date=20161214T193306Z\u0026X-Amz-Security-Token=FQoDYXdzEMT//////////wEaDMj3NLTbn4Y3JgbItSK3A57LyrcXBHQlP6lM7cT/2N9naRgRSef4EG/AxCCjMGcEVdt4X5ZsfHdzNiD6L0GODXmrP3quoXNBNZCoUVo3DY5E0P67iz9tYC2Ac%2BILJ%2BBzELNz84XI7C9zg6CCecZ8oeNjCTJXsMZ3xLx2bN099sl%2BY5nduDXAxen2Z63QKw7kiuuEXin/z%2B4ywFSP/Z1Sqbjkq4Qwjs5FUSyyz61wjl1%2Bg8uIJ5u3HTOlb8eZpk7gUCtdmLIE7mK1eZe5azUJC8XBW7Eu7jaRyM2PKMwjVnwepnfgPyEDqJSzKYJt1bGXgnQEN7logEKNOjmOcJqggM5Tc7PD40USAveIQ6E8ny/X0N%2BZ/X1rZTaCiAH1aWwVNqa0M43mlECrBeDv9I9BRMJzp4btvEgHKODrJe2MawDu4L1%2BzVNgOD7TZjrFt9zSEpyQK79dh8oHuyzDL0C%2Bpw3zL2ambsJ5OX6UnMuAmrkBbin1PKh2nHFkL/0xXAb2ZbSV6vKBxzKeQ62HMvv8UqypKbkwOMnstxyGGp00r6m6vL62x%2BTDergiiRfs947NyfJnP5l/rNRNMNesGo6kBmAqpACaBPAo0Z3GwgU%3D\u0026X-Amz-Algorithm=AWS4-HMAC-SHA256\u0026X-Amz-Credential=ASIAIB72YBSAAINUZRPQ/20161214/us-east-1/s3/aws4_request\u0026X-Amz-SignedHeaders=host\u0026X-Amz-Signature=f9bfb2b8d6114bccb6e88e4c0526bf19c5658b587ee368d04b42b1881d5359db' }

  describe 'documented problem with carrierwave/fog' do
    describe CarrierWave::SanitizedFile do
      it 'cannot handle S3 URI' do
        # if the following trips, it means we *might* be able to use just carrierwave/fog again, w/o carrierwave-aws
        expect(described_class.new(bigurl).filename).not_to eq 'image.png'
      end
    end
  end

  shared_examples 'Regular upload' do
    it 'mounts Uploader as expected' do
      expect(upload.file).to be_a Hyrax::UploadedFileUploader
      expect(upload.file).to be_a CarrierWave::Uploader::Base
    end
    it 'Gives clean filename and object' do
      expect(upload.file.filename).to eq 'world.png'
    end
  end

  describe CarrierWave::Storage::File do # default in dev/test
    it_behaves_like 'Regular upload'
    it 'returns a SanitizedFile' do
      expect(upload.file.file).to be_a CarrierWave::SanitizedFile
    end
  end

  describe 'per-tenant upload limits' do
    # world.png is 4218 bytes with content type image/png
    let(:account) { FactoryBot.build(:account, settings:) }
    let(:settings) { {} }
    let(:user) { FactoryBot.create(:user) }

    before { allow(Site).to receive(:account).and_return(account) }

    context 'with no restrictive settings' do
      it 'accepts the upload' do
        expect(Hyrax::UploadedFile.new(file:, user:)).to be_valid
      end
    end

    context 'when no tenant account is present' do
      let(:account) { nil }

      it 'accepts the upload' do
        expect(Hyrax::UploadedFile.new(file:, user:)).to be_valid
      end
    end

    context 'when the file is within the tenant file size limit' do
      let(:settings) { { file_size_limit: '1000000' } }

      it 'accepts the upload' do
        expect(Hyrax::UploadedFile.new(file:, user:)).to be_valid
      end
    end

    context 'when the file exceeds the tenant file size limit' do
      let(:settings) { { file_size_limit: '1000' } }

      it 'rejects the upload with a readable message' do
        uploaded = Hyrax::UploadedFile.new(file:, user:)

        expect(uploaded).not_to be_valid
        expect(uploaded.errors[:base].join).to include('file size limit')
      end

      it 'still accepts a record with no file content' do
        expect(Hyrax::UploadedFile.new(user:)).to be_valid
      end
    end

    context 'when the limit tightens after the file was stored' do
      let(:settings) { { file_size_limit: '1000000' } }

      it 'is re-checked on later saves' do
        uploaded = Hyrax::UploadedFile.create(file:, user:)
        account.file_size_limit = '1000'

        expect(uploaded.save).to eq(false)
      end
    end

    context 'when the content type is allowed' do
      let(:settings) { { allowed_content_types: 'image/png, application/pdf' } }

      it 'accepts the upload' do
        expect(Hyrax::UploadedFile.new(file:, user:)).to be_valid
      end
    end

    context 'when a wildcard content type matches' do
      let(:settings) { { allowed_content_types: 'image/*' } }

      it 'accepts the upload' do
        expect(Hyrax::UploadedFile.new(file:, user:)).to be_valid
      end
    end

    context 'when the content type is not allowed' do
      let(:settings) { { allowed_content_types: 'application/pdf' } }

      it 'rejects the upload with a readable message' do
        uploaded = Hyrax::UploadedFile.new(file:, user:)

        expect(uploaded).not_to be_valid
        expect(uploaded.errors[:base].join).to include('not accepted')
      end
    end

    context 'when the tenant has storage remaining under its ceiling' do
      let(:settings) { { storage_limit: '10000' } }

      before { allow(UploadLimitsService).to receive(:current_storage_usage).and_return(0) }

      it 'accepts the upload' do
        expect(Hyrax::UploadedFile.new(file:, user:)).to be_valid
      end
    end

    context 'when the tenant is at its storage ceiling' do
      let(:settings) { { storage_limit: '10000' } }

      before { allow(UploadLimitsService).to receive(:current_storage_usage).and_return(10_000) }

      it 'rejects the upload with a readable message' do
        uploaded = Hyrax::UploadedFile.new(file:, user:)

        expect(uploaded).not_to be_valid
        expect(uploaded.errors[:base].join).to include('storage limit')
      end
    end
  end

  # With aws configured, without S3 credentials or stubbing, we would get failures from requests made
  # by the underlying library and errors telling us to:
  #   stub_request(:get, "http://169.254.169.254/latest/meta-data/iam/security-credentials/")
  #     .with(:headers => {'Host'=>'169.254.169.254:80', 'User-Agent'=>'excon/0.55.0'})
  #     .to_return(:status => 200, :body => 'AWS_DEFAULT_REGION', :headers => {})
  #   stub_request(:get, "http://169.254.169.254/latest/meta-data/placement/availability-zone/") ...
  #   stub_request(:get, "http://169.254.169.254/latest/meta-data/iam/security-credentials/AWS_DEFAULT_REGION") ...

  # Therefore we use a trivial actual S3 bucket to enable these tests, as does carrierwave-aws itself.
  # :aws group is excluded by default in spec_helper. To run these, use: `rspec --tag aws`
  describe CarrierWave::Storage::AWS, :aws do
    let(:file) do
      # In Controller each file is like:
      ActionDispatch::Http::UploadedFile.new(
        tempfile: Tempfile.new,
        filename: 'world.png',
        content_type: 'image/png',
        headers: "Content-Disposition: form-data; name=\"files[]\"; filename=\"world.png\"\r\nContent-Type: image/png\r\nContent-Length: 4218\r\n"
      )
    end

    let!(:config) do
      # reproduce initializer, since it is too late to trigger it by mocking Settings
      CarrierWave.configure do |config|
        config.fog_provider = 'fog/aws'
        config.storage = :aws
        config.aws_bucket = bucket_name
        config.aws_acl = 'bucket-owner-full-control'
        config
      end
    end

    after(:all) do
      CarrierWave.configure do |config|
        config.storage = :file # revert to default
      end
    end

    describe 'configuration' do
      it 'has CarrierWave-AWS values available' do
        expect(config.storage_engines).to match a_hash_including(aws: 'CarrierWave::Storage::AWS')
      end
      it 'has correct storage and bucket' do
        expect(config.storage).to eq(CarrierWave::Storage::AWS)
        expect(config.aws_bucket).to eq(bucket_name)
      end
    end

    describe CarrierWave::Support::UriFilename do # provided by carrierwave-aws
      it 'helper method can handle S3 URI' do
        expect(described_class.filename(bigurl)). to eq 'image.png'
      end
    end

    describe CarrierWave::Storage::AWSFile do
      it_behaves_like 'Regular upload'

      it 'upload.file.file returns an AWSFile' do
        expect(upload.file.file).to be_a described_class
      end

      describe 'unlike our documented issue' do
        before { allow(upload.file.file).to receive(:url).and_return(bigurl) }

        it 'can handle S3 URI' do
          expect(upload.file.file.filename).to eq 'image.png'
        end
      end
    end
  end
end
# rubocop:enable Metrics/MethodLength
