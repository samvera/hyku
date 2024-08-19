# frozen_string_literal: true

# For work approval permissions, see spec/requests/work_approval_permissions_spec.rb
RSpec.describe 'Work Depositor role', type: :request, singletenant: true, clean: true do
  let(:work_depositor) { FactoryBot.create(:user, roles: [:work_depositor]) }
  let(:work) { create(:work) }

  before do
    FactoryBot.create(:admin_group)
    FactoryBot.create(:registered_group)
    FactoryBot.create(:editors_group)
    FactoryBot.create(:depositors_group)

    login_as work_depositor
  end

  describe 'read permissions' do
    let!(:admin_set_id) { Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id }

    before do
      solr = Blacklight.default_index.connection

      solr.add(work.to_solr)
      solr.commit
    end

    %w[open authenticated].each do |visibility|
      context "with #{visibility} visibility" do
        let(:work) { FactoryBot.valkyrie_create(:generic_work_resource, title: "Lacey and Ollie Forever", visibility_setting: visibility, admin_set_id:) }

        it "can see the work's public show page" do
          get hyrax_generic_work_path(work)

          expect(response).to have_http_status(:success)
        end

        it 'can see the work in search results' do
          work

          get search_catalog_path

          expect(response).to have_http_status(:success)

          expect(response.body).to include(work.title.first)
        end
      end
    end

    context 'with restricted visibility' do
      let(:work) { FactoryBot.valkyrie_create(:generic_work_resource, title: "Lacey and Ollie Forever", visibility_setting: 'restricted', admin_set_id:) }

      it "cannot see the work's show page" do
        get hyrax_generic_work_path(work)

        expect(response).to have_http_status(:unauthorized)
      end

      it 'cannot see the work in search results' do
        get search_catalog_path

        expect(response).to have_http_status(:success)
        expect(response.body).not_to include(work.title.first)
      end
    end
  end

  describe 'create permissions' do
    let(:valid_work_params) do
      {
        generic_work: {
          title: ['Test Work'],
          creator: [work_depositor.email],
          keyword: ['asdf'],
          rights_statement: 'http://rightsstatements.org/vocab/CNE/1.0/'
        }
      }
    end

    it 'can see the work form' do
      get new_hyrax_generic_work_path
      expect(response).to have_http_status(:success)
    end

    # This is commented out as I was encountering issues reported here:
    # https://github.com/samvera/hyrax/issues/6775
    xit 'can create a work' do
      expect(Ability.new(work_depositor).can?(:create, GenericWorkResource)).to be_truthy

      expect do
        post hyrax_generic_works_path, params: valid_work_params
      end.to change { Hyrax.query_service.count_all_of_model(model: GenericWorkResource) }.by(1)
    end
  end

  describe 'edit permissions' do
    it 'cannot edit the work' do
      get edit_hyrax_generic_work_path(work)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'destroy permissions' do
    it 'cannot destroy the work' do
      delete hyrax_generic_work_path(work)

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
