# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::UploadsController, type: :controller do
  routes { Hyrax::Engine.routes }

  let(:user) { FactoryBot.create(:user) }
  let(:fixture) { Rails.root.join('spec', 'fixtures', 'files', 'text_file.txt') }
  let(:file) { Rack::Test::UploadedFile.new(fixture, 'text/plain') }
  let(:file_size) { File.size(fixture) }
  let(:account) { Account.from_request(nil) }

  def stub_limit(bytes)
    allow(account).to receive(:file_size_limit).and_return(bytes&.to_s)
  end

  before do
    allow(Site).to receive(:account).and_return(account)
    sign_in user
  end

  describe 'POST #create' do
    context 'with no limit configured' do
      it 'accepts the upload' do
        stub_limit(nil)
        expect { post :create, params: { files: [file], format: 'json' } }
          .to change(Hyrax::UploadedFile, :count).by(1)
        expect(response).to be_successful
      end
    end

    context 'with a non-numeric limit' do
      it 'disables the check rather than misreading "5 GB" as five bytes' do
        stub_limit('5 GB')
        post :create, params: { files: [file], format: 'json' }
        expect(response).not_to have_http_status(:payload_too_large)
      end
    end

    context 'with a limit the file fits inside' do
      it 'accepts the upload' do
        stub_limit(file_size + 1)
        expect { post :create, params: { files: [file], format: 'json' } }
          .to change(Hyrax::UploadedFile, :count).by(1)
        expect(response).to be_successful
      end
    end

    context 'with a limit the file exceeds' do
      before { stub_limit(file_size - 1) }

      it 'refuses with 413 and an error blueimp can render' do
        post :create, params: { files: [file], format: 'json' }

        expect(response).to have_http_status(:payload_too_large)
        expect(JSON.parse(response.body)['files'].first['error']).to match(/upload limit/)
      end

      it 'creates no UploadedFile' do
        expect { post :create, params: { files: [file], format: 'json' } }
          .not_to change(Hyrax::UploadedFile, :count)
      end
    end

    describe 'chunked uploads' do
      let(:existing) { Hyrax::UploadedFile.create!(file:, user:) }
      let(:on_disk) { File.size(existing.file.path) }

      def append_chunk
        request.headers['CONTENT-RANGE'] = "bytes #{on_disk}-#{(on_disk + file_size) - 1}/#{on_disk + file_size}"
        post :create, params: { id: existing.id, files: [file], format: 'json' }
      end

      it 'refuses an append that would exceed the limit' do
        stub_limit(on_disk + file_size - 1)
        append_chunk

        expect(response).to have_http_status(:payload_too_large)
      end

      it 'accepts an append that stays under the limit' do
        stub_limit(on_disk + file_size + 1)
        append_chunk

        expect(response).not_to have_http_status(:payload_too_large)
      end

      it 'does not count existing bytes when replacing rather than appending' do
        stub_limit(file_size + 1)
        post :create, params: { id: existing.id, files: [file], format: 'json' }

        expect(response).not_to have_http_status(:payload_too_large)
      end
    end
  end
end
