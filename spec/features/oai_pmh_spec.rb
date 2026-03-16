# frozen_string_literal: true

RSpec.describe "OAI PMH Support", type: :feature do
  let(:user) { create(:user) }
  let(:work) { create(:work, user:) }
  let(:identifier) { work.id }

  before do
    # We use Site.instance.account.cname to build the download links.
    # In the test ENV, Site.instance.account is nil.
    account = Account.create(name: 'test', cname: 'test.example.com')
    account.sites << Site.instance
    account.save

    login_as(user, scope: :user)
    work
  end

  context 'oai interface with works present' do
    it 'lists metadata prefixes' do
      visit oai_catalog_path(verb: 'ListMetadataFormats')
      expect(page).to have_content('oai_dc')
      expect(page).to have_content('oai_hyku')
    end

    %w[oai_dc oai_hyku].each do |metadata_prefix|
      context "with the #{metadata_prefix} prefix" do
        it 'retrieves a list of records' do
          visit oai_catalog_path(verb: 'ListRecords', metadataPrefix: metadata_prefix)
          expect(page).to have_content("#{Site.account.oai_prefix}:#{identifier}")
          expect(page).to have_content(work.title.first)
        end

        it 'retrieves a single record' do
          visit oai_catalog_path(verb: 'GetRecord', metadataPrefix: metadata_prefix, identifier:)
          expect(page).to have_content("#{Site.account.oai_prefix}:#{identifier}")
          expect(page).to have_content(work.title.first)
        end

        it 'retrieves a list of identifiers' do
          visit oai_catalog_path(verb: 'ListIdentifiers', metadataPrefix: metadata_prefix)
          expect(page).to have_content("#{Site.account.oai_prefix}:#{identifier}")
          expect(page).not_to have_content(work.title.first)
        end
      end
    end
  end

  context 'when using the oai_hyku prefix' do
    let(:metadata_prefix) { 'oai_hyku' }

    it 'includes non-DC fields' do
      work.keyword = ['asdf']
      work.abstract = ['fdsa']
      work.save

      visit oai_catalog_path(verb: 'ListRecords', metadataPrefix: metadata_prefix)

      expect(page).to have_content("#{Site.account.oai_prefix}:#{identifier}")
      expect(page).to have_content(work.title.first)
      expect(page).to have_content('asdf')
      expect(page).to have_content('fdsa')
    end

    describe '#add_public_file_urls' do
      let(:record) { { member_ids_ssim: ['my-file-set-id-1', 'my-file-set-id-2'] } }
      let(:xml) { Builder::XmlMarkup.new }

      # We use Site.instance.account.cname to build the download links.
      # In the test ENV, Site.instance.account is nil.
      before do
        account = Account.create(name: 'test', cname: 'test.example.com')
        account.sites << Site.instance
        account.save
      end

      context 'when the work has public file sets' do
        before do
          # Mock two public file set ids returned by Solr
          allow(Hyrax::SolrService)
            .to receive(:query)
            .and_return([{ 'id' => 'my-file-set-id-1' }, { 'id' => 'my-file-set-id-2' }])
        end

        it 'adds download links' do
          expect(xml.to_s).not_to include('my-file-set-id-1', 'my-file-set-id-2')

          Oai::Provider::MetadataFormat::HykuDublinCore
            .send(:new)
            .add_public_file_urls(xml, record)

          expect(xml.to_s).to include('<file_url>https://test.example.com/downloads/my-file-set-id-1</file_url>')
          expect(xml.to_s).to include('<file_url>https://test.example.com/downloads/my-file-set-id-2</file_url>')
        end
      end

      context 'when the work has non-public file sets' do
        before do
          # Mock zero public file set ids returned by Solr
          allow(Hyrax::SolrService)
            .to receive(:query)
            .and_return([])
        end

        it 'does not add download links' do
          expect(xml.to_s).not_to include('my-file-set-id-1', 'my-file-set-id-2')

          Oai::Provider::MetadataFormat::HykuDublinCore
            .send(:new)
            .add_public_file_urls(xml, record)

          expect(xml.to_s).not_to include('<file_url>https://test.example.com/downloads/my-file-set-id-1</file_url>')
          expect(xml.to_s).not_to include('<file_url>https://test.example.com/downloads/my-file-set-id-2</file_url>')
        end
      end

      context 'when the work has public and non-public file sets' do
        before do
          # Mock one public file set ids returned by Solr
          allow(Hyrax::SolrService)
            .to receive(:query)
            .and_return([{ 'id' => 'my-file-set-id-1' }])
        end

        it 'adds public download links' do
          expect(xml.to_s).not_to include('my-file-set-id-1', 'my-file-set-id-2')

          Oai::Provider::MetadataFormat::HykuDublinCore
            .send(:new)
            .add_public_file_urls(xml, record)

          expect(xml.to_s).to include('<file_url>https://test.example.com/downloads/my-file-set-id-1</file_url>')
          expect(xml.to_s).not_to include('<file_url>https://test.example.com/downloads/my-file-set-id-2</file_url>')
        end
      end
    end
  end
end
