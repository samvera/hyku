# frozen_string_literal: true

RSpec.describe CatalogController do
  # Hyku solr/conf/solrconfig.xml does not define per-field spellcheck dictionaries
  # (e.g. creator, publisher); sending them caused Solr errors / Blacklight InvalidRequest.
  describe "search field Solr params (spellcheck regression)" do
    %w[
      contributor
      creator
      title
      description
      publisher
      date_created
      subject
      language
      resource_type
      format
      identifier
      based_near_label
      keyword
    ].each do |key|
      it "does not set spellcheck.dictionary on #{key} search field" do
        field = described_class.blacklight_config.search_fields[key]
        expect(field).to be_present, "expected search_fields['#{key}'] to exist"
        solr_keys = (field.solr_parameters || {}).stringify_keys.keys
        expect(solr_keys).not_to include("spellcheck.dictionary")
      end
    end
  end

  describe "GET /show" do
    let(:file_set) { create(:file_set) }

    context "with access" do
      before do
        sign_in create(:user)
        allow(controller).to receive(:can?).and_return(true)
      end

      it "is successful" do
        get :show, params: { id: file_set }
        expect(response).to be_successful
        expect(response.content_type).to eq "application/json; charset=utf-8"
      end
    end

    context "without access" do
      it "is redirects to sign in" do
        get :show, params: { id: file_set }
        expect(response).to redirect_to new_user_session_path
      end
    end
  end
end
