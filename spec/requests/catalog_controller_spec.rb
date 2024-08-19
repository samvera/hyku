# frozen_string_literal: true

require "spec_helper"

RSpec.describe CatalogController, type: :request, clean: true, multitenant: true do
  let(:user) { create(:user, email: 'test_user@repo-sample.edu') }
  let(:work) { build(:work, title: ['welcome test'], id: SecureRandom.uuid, user:) }
  let(:hyku_sample_work) { build(:work, title: ['sample test'], id: SecureRandom.uuid, user:) }
  let(:sample_solr_connection) { RSolr.connect url: "#{ENV['SOLR_URL']}hydra-sample" }

  let(:cross_search_solr) { create(:solr_endpoint, url: "#{ENV['SOLR_URL']}hydra-cross-search-tenant") }
  let!(:cross_search_tenant_account) do
    create(:account,
           name: 'cross_search',
           cname: 'example.com',
           solr_endpoint: cross_search_solr,
           fcrepo_endpoint: nil)
  end

  before do
    WebMock.disable!
    allow(AccountElevator).to receive(:switch!).with(cross_search_tenant_account.cname).and_return('public')
    allow(Apartment::Tenant.adapter).to receive(:connect_to_new).and_return('')
    allow_any_instance_of(Hyrax::SolrServiceDecorator).to receive(:connection).and_return(sample_solr_connection)

    Hyrax::SolrService.add(hyku_sample_work.to_solr)
    Hyrax::SolrService.commit

    Hyrax::SolrService.reset!
    Hyrax::SolrService.add(work.to_solr)
    Hyrax::SolrService.commit
  end

  after do
    WebMock.enable!

    Hyrax::SolrService.delete(hyku_sample_work.id)
    Hyrax::SolrService.commit

    SolrEndpoint.reset!
    Hyrax::SolrService.delete(work.id)
    Hyrax::SolrService.commit
  end

  describe 'Cross Tenant Search' do
    let(:cross_tenant_solr_options) do
      {
        "read_timeout" => 120,
        "open_timeout" => 120,
        "url" => "#{ENV['SOLR_URL']}hydra-cross-search-tenant",
        "adapter" => "solr"
      }
    end

    let(:black_light_config) { Blacklight::Configuration.new(connection_config: cross_tenant_solr_options) }

    before do
      host! "http://#{cross_search_tenant_account.cname}/"
      black_light_config.add_search_field('title') do |field|
        field.solr_parameters = {
          "spellcheck.dictionary": "title"
        }
        solr_name = 'title_tesim'
        field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
        }
      end
      black_light_config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
      black_light_config.advanced_search[:query_parser] ||= 'dismax'
    end

    context 'can fetch data from other tenants' do
      it 'cross-search-tenant can fetch all record in child tenants' do
        connection = RSolr.connect(url: "#{ENV['SOLR_URL']}hydra-cross-search-tenant")
        allow_any_instance_of(Blacklight::Solr::Repository).to receive(:build_connection).and_return(connection)
        allow(CatalogController).to receive(:blacklight_config).and_return(black_light_config)

        # get '/catalog', params: { q: '*' }
        # get search_catalog_url, params: { locale: 'en', q: 'test' }
        get "http://#{cross_search_tenant_account.cname}/catalog?q=test", params: { q: 'title' }
        expect(response.status).to eq(200)
      end
    end
  end
end
