# frozen_string_literal: true

RSpec.describe 'api/sushi/r51', type: :request, singletenant: true do
  before { create_hyrax_countermetric_objects }
  let(:required_parameters) do
    {
      begin_date: '2022-01',
      end_date: '2022-02'
    }
  end

  RSpec.shared_examples 'without required parameters' do |endpoint|
    it 'returns a 422 unprocessable entity' do
      get "/api/sushi/r51/reports/#{endpoint}"
      expect(response).to have_http_status(422)
    end
  end

  describe 'GET /api/sushi/r51/reports/ir' do
    it_behaves_like 'without required parameters', 'ir'

    it 'returns a 200 with correct response for item report' do
      get '/api/sushi/r51/reports/ir', params: required_parameters
      expect(response).to have_http_status(200)
      parsed_body = JSON.parse(response.body)
      expect(parsed_body.dig('Report_Header', 'Report_Name')).to eq('Item Report')
    end

    context 'with a valid item_id parameter' do
      it 'returns a 200 status report for the given item' do
        get '/api/sushi/r51/reports/ir', params: { **required_parameters, item_id: '54321' }
        expect(response).to have_http_status(200)
        parsed_body = JSON.parse(response.body)
        expect(parsed_body['Report_Items']).to be_instance_of(Array)
      end
    end

    context 'with an invalid item_id parameter' do
      it 'returns a 422 status report for the given item' do
        get '/api/sushi/r51/reports/ir', params: { **required_parameters, item_id: 'qwerty123' }
        expect(response).to have_http_status(422)
        parsed_body = JSON.parse(response.body)

        expect(parsed_body['Code']).to eq(3060)
      end
    end
  end

  describe 'GET /api/sushi/r51/reports/pr (e.g. platform report)' do
    it_behaves_like 'without required parameters', 'pr'

    it 'returns a 200 status' do
      get '/api/sushi/r51/reports/pr', params: required_parameters
      expect(response).to have_http_status(200)
      parsed_body = JSON.parse(response.body)
      expect(parsed_body.dig('Report_Header', 'Report_Name')).to eq('Platform Report')
    end
  end

  describe 'GET /api/sushi/r51/reports/pr_p1 (e.g. platform usage report)' do
    it_behaves_like 'without required parameters', 'pr_p1'

    it 'returns a 200 status' do
      get '/api/sushi/r51/reports/pr_p1', params: required_parameters
      expect(response).to have_http_status(200)
      parsed_body = JSON.parse(response.body)
      expect(parsed_body.dig('Report_Header', 'Report_Name')).to eq('Platform Usage')
    end
  end

  describe 'GET /api/sushi/r51/status (e.g. platform status)' do
    it 'returns a 200 status' do
      get '/api/sushi/r51/status'
      expect(response).to have_http_status(200)
      parsed_body = JSON.parse(response.body)
      expect(parsed_body.dig(0, 'Description')).to include('COUNTER Usage Reports')
    end
  end

  describe 'GET /api/sushi/r51/reports (e.g. reports list)' do
    it 'returns a 200 status' do
      get '/api/sushi/r51/reports'
      expect(response).to have_http_status(200)
      parsed_body = JSON.parse(response.body)
      expect(parsed_body.first).to have_key('Report_Name')
      expect(parsed_body.first).to have_key('Report_ID')
      expect(parsed_body.first).to have_key('Release')
      expect(parsed_body.first).to have_key('Report_Description')
      expect(parsed_body.first).to have_key('Path')
      expect(parsed_body.last).to have_key('First_Month_Available')
      expect(parsed_body.last).to have_key('Last_Month_Available')
    end
  end
end
