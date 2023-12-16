# frozen_string_literal: true

RSpec.describe SharedSearchHelper do
  let(:helper) { _view }

  context "shared search records" do
    let(:cname) { 'hyku-me.test' }
    let(:account) { build(:search_only_account, cname:) }

    let(:uuid) { SecureRandom.uuid }
    let(:request) { instance_double(ActionDispatch::Request, port: 3000, protocol: "https://", host: account.cname) }
    let(:work_hash) { { id: uuid, 'has_model_ssim': ['GenericWork'], 'account_cname_tesim': account.cname } }

    before do
      allow(helper).to receive(:current_account) { account }
    end

    it 'returns #generate_work_url for production' do
      allow(Rails.env).to receive(:development?).and_return(false)
      allow(Rails.env).to receive(:test?).and_return(false)
      url = "#{request.protocol}#{cname}/concern/generic_works/#{uuid}"
      expect(helper.generate_work_url(work_hash, request)).to eq(url)
    end

    it 'returns #generate_work_url for development' do
      account.cname = 'hyku.docker'
      url = "#{request.protocol}#{account.cname}:#{request.port}/concern/generic_works/#{uuid}"
      expect(helper.generate_work_url(work_hash, request)).to eq(url)
    end
  end
end
