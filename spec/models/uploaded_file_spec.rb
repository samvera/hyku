# frozen_string_literal: true

# Much of this testing is the complex configurable stuff underneath UploadedFile
# and simulating the AWS configuration that would be in production.

# rubocop:disable Metrics/LineLength
RSpec.describe 'Hyrax::UploadedFile' do # rubocop:disable RSpec/DescribeClass
  let(:file) { File.open(fixture_path + '/images/world.png') }
  let(:upload) { Hyrax::UploadedFile.create(file: file) }
  let(:config) { CarrierWave.configure { |c| c } }
  let(:bucket_name) { 'hyku-carrierwave-test' }
  let(:bigurl) { 'https://demo-application-w5twjcsuyx3v-uploadbucket-4l1zpvmp62nf.s3.amazonaws.com//var/app/current/tmp/uploads/hyrax/uploaded_file/file/31/image.png?X-Amz-Expires=600\u0026X-Amz-Date=20161214T193306Z\u0026X-Amz-Security-Token=FQoDYXdzEMT//////////wEaDMj3NLTbn4Y3JgbItSK3A57LyrcXBHQlP6lM7cT/2N9naRgRSef4EG/AxCCjMGcEVdt4X5ZsfHdzNiD6L0GODXmrP3quoXNBNZCoUVo3DY5E0P67iz9tYC2Ac%2BILJ%2BBzELNz84XI7C9zg6CCecZ8oeNjCTJXsMZ3xLx2bN099sl%2BY5nduDXAxen2Z63QKw7kiuuEXin/z%2B4ywFSP/Z1Sqbjkq4Qwjs5FUSyyz61wjl1%2Bg8uIJ5u3HTOlb8eZpk7gUCtdmLIE7mK1eZe5azUJC8XBW7Eu7jaRyM2PKMwjVnwepnfgPyEDqJSzKYJt1bGXgnQEN7logEKNOjmOcJqggM5Tc7PD40USAveIQ6E8ny/X0N%2BZ/X1rZTaCiAH1aWwVNqa0M43mlECrBeDv9I9BRMJzp4btvEgHKODrJe2MawDu4L1%2BzVNgOD7TZjrFt9zSEpyQK79dh8oHuyzDL0C%2Bpw3zL2ambsJ5OX6UnMuAmrkBbin1PKh2nHFkL/0xXAb2ZbSV6vKBxzKeQ62HMvv8UqypKbkwOMnstxyGGp00r6m6vL62x%2BTDergiiRfs947NyfJnP5l/rNRNMNesGo6kBmAqpACaBPAo0Z3GwgU%3D\u0026X-Amz-Algorithm=AWS4-HMAC-SHA256\u0026X-Amz-Credential=ASIAIB72YBSAAINUZRPQ/20161214/us-east-1/s3/aws4_request\u0026X-Amz-SignedHeaders=host\u0026X-Amz-Signature=f9bfb2b8d6114bccb6e88e4c0526bf19c5658b587ee368d04b42b1881d5359db' }

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
    before { expect(Hyrax::UploadedFileUploader).to receive(:storage).and_return(described_class) }

    it_behaves_like 'Regular upload'
    it 'returns a SanitizedFile' do
      expect(upload.file.file).to be_a CarrierWave::SanitizedFile
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
# rubocop:enable Metrics/LineLength
