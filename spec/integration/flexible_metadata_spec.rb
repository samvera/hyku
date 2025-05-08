# frozen_string_literal: true

RSpec.describe "Flexible Metadata", type: :integration do
  # before(:each) do
  #   @flexible = ENV['HYRAX_FLEXIBLE']
  #   ENV['HYRAX_FLEXIBLE'] = 'true'
  # end

  # after(:each) do
  #   ENV['HYRAX_FLEXIBLE'] = @flexible
  # end

  describe "when adding new properties to schema" do
    before do
      account = Account.new(name: 'test')
      CreateAccount.new(account).save
      switch!(account)
    end

    let(:user) { create(:user) }
    let(:admin_set_id) { Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id.to_s }
    let(:yaml_content) do
      <<~YAML
        properties:
          foo:
            available_on:
              class:
              - GenericWorkResource
            cardinality:
              minimum: 1
            multi_value: true
            controlled_values:
              format: http://www.w3.org/2001/XMLSchema#string
              sources:
              - 'null'
            definition:
              default: Enter a standardized foo for display. If only one foo is needed,
                transcribe the foo from the source itself.
            display_label:
              default: Foo
            index_documentation: displayable, searchable
            indexing:
            - foo_sim
            - foo_tesim
            form:
              required: true
              primary: true
              multiple: true
            property_uri: https://hykucommons.org/terms/foo
            range: http://www.w3.org/2001/XMLSchema#string
            requirement: required
            sample_values:
            - I pity the foo
            view:
              label:
                en: Foo
                es: Foo
              html_dl: true
      YAML
    end

    it "handles newly added properties without requiring server restart" do
      work_1 = GenericWorkResource.new
      work_1.depositor = user.email
      work_1.admin_set_id = admin_set_id

      form_class = Hyrax::WorkFormService.form_class(work_1)
      form = form_class.new(resource: work_1)

      params_1 = {
        'generic_work' => {
          'title' => ['Test Work Before Schema Change'],
          'creator' => ['Test Creator']
        }
      }

      expect(form.validate(params_1['generic_work'])).to be true

      action = Hyrax::Action::CreateValkyrieWork.new(
        form: form,
        transactions: Hyrax::Transactions::Container,
        user: user,
        params: params_1,
        work_attributes_key: 'generic_work'
      )

      expect(action.validate).to be true
      result = action.perform
      expect(result).to be_success
      work_1 = result.value!
      expect(work_1.title).to eq(['Test Work Before Schema Change'])

      profile = Hyrax::FlexibleSchema.current_version.deep_dup
      foo_properties = YAML.safe_load(yaml_content)
      profile['properties'] = foo_properties['properties'].merge(profile['properties'])
      new_schema = Hyrax::FlexibleSchema.new
      new_schema.profile = profile
      new_schema.save!

      work_2 = GenericWorkResource.new
      work_2.depositor = user.email
      work_2.admin_set_id = admin_set_id

      form_class = Hyrax::WorkFormService.form_class(work_2)
      form = form_class.new(resource: work_2)

      params_2 = {
        'generic_work' => {
          'title' => ['Test Work After Schema Change'],
          'creator' => ['Test Creator'],
          'foo' => ['New property']
        }
      }

      expect(form.validate(params_2['generic_work'])).to be true

      action = Hyrax::Action::CreateValkyrieWork.new(
        form: form,
        transactions: Hyrax::Transactions::Container,
        user: user,
        params: params_2,
        work_attributes_key: 'generic_work'
      )

      expect(action.validate).to be true

      result = action.perform
      expect(result).to be_success

      work2 = result.value!
      expect(work2.title).to eq(['Test Work After Schema Change'])
      expect(work2.foo).to eq(['New property'])
    end
  end
end
