# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::DownloadsController, type: :controller do
  routes { Hyrax::Engine.routes }

  let(:user) { create(:user) }
  let(:work) { FactoryBot.valkyrie_create(:generic_work_resource, :with_one_file_set, depositor: user.user_key) }
  let(:file_set_id) { work.member_ids.first.to_s }

  before { sign_in user }

  describe '#file_set_parent (decorator)' do
    context 'when Wings is not loaded' do
      before { with_disable_wings(true) }

      it 'does not raise NameError for Wings::Valkyrie' do
        expect { controller.send(:file_set_parent, file_set_id) }.not_to raise_error
      end

      it 'returns the parent work' do
        parent = controller.send(:file_set_parent, file_set_id)
        expect(parent).to be_a Hyrax::Resource
        expect(parent.id.to_s).to eq work.id.to_s
      end
    end
  end

  describe '#show with thumbnail' do
    let(:derivative_path) do
      Hyrax::DerivativePath.derivative_path_for_reference(file_set_id, 'thumbnail')
    end

    before do
      with_disable_wings(true)
      allow(controller).to receive(:authorize!).and_return(true)
      allow(controller).to receive(:workflow_restriction?).and_return(false)
      FileUtils.mkdir_p(File.dirname(derivative_path))
      File.write(derivative_path, "fake-jpeg-content")
    end

    after do
      FileUtils.rm_f(derivative_path)
    end

    it 'serves the thumbnail without raising Wings errors' do
      get :show, params: { id: file_set_id, file: 'thumbnail' }
      expect(response).to be_successful
    end
  end
end
