# frozen_string_literal: true

RSpec.describe Hyrax::UploadsController, type: :controller do
  routes { Hyrax::Engine.routes }

  let(:user) { create(:user) }
  let(:account) { build(:account, settings:) }
  let(:settings) { { file_size_limit: '1000' } }
  # world.png is 4218 bytes with content type image/png
  let(:file) { fixture_file_upload('images/world.png', 'image/png') }

  before do
    sign_in user
    allow(Site).to receive(:account).and_return(account)
  end

  describe '#create' do
    context 'when the file exceeds the tenant file size limit' do
      it 'does not keep the upload' do
        expect { post :create, params: { files: [file], format: 'json' } }
          .not_to change(Hyrax::UploadedFile, :count)
      end

      it 'responds with a readable per-file error for the upload widget' do
        post :create, params: { files: [file], format: 'json' }

        expect(response).to be_successful
        error = JSON.parse(response.body).dig('files', 0, 'error')
        expect(error).to include('file size limit')
      end
    end

    context 'when the file is within the tenant file size limit' do
      let(:settings) { { file_size_limit: '1000000' } }

      it 'creates the upload' do
        expect { post :create, params: { files: [file], format: 'json' } }
          .to change(Hyrax::UploadedFile, :count).by(1)
      end
    end

    context 'when the file content type is not accepted by the tenant' do
      let(:settings) { { allowed_content_types: 'application/pdf' } }

      it 'responds with a readable per-file error for the upload widget' do
        post :create, params: { files: [file], format: 'json' }

        error = JSON.parse(response.body).dig('files', 0, 'error')
        expect(error).to include('not accepted')
      end
    end
  end
end
