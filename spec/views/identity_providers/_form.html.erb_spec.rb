# frozen_string_literal: true

RSpec.describe 'identity_providers/_form', type: :view do
  before do
    # stub omniauth providers since the form iterates over them
    allow(Devise).to receive(:omniauth_providers).and_return(%i[saml cas openid_connect])
  end

  # a new form should have the correct fields, instructions, and buttons
  context 'when creating a new identity provider' do
    # mocking a new identity provider view
    before do
      # assign the instance variables the form expects
      assign(:identity_provider, IdentityProvider.new)
      assign(:provider_collection, Devise.omniauth_providers.map { |o| [o, o.upcase] })
      # render the form partial
      render
    end

    it 'renders a form' do
      expect(rendered).to have_selector('form')
    end

    it 'has a Name or Description text field' do
      expect(rendered).to have_selector('input[name="identity_provider[name]"]')
    end

    it 'has a Provider select field with options' do
      expect(rendered).to have_selector('select[name="identity_provider[provider]"]')
      expect(rendered).to have_text('SAML')
      expect(rendered).to have_text('CAS')
      expect(rendered).to have_text('Openid Connect')
    end

    it 'has an Options textarea field' do
      expect(rendered).to have_selector('textarea[name="identity_provider[options]"]')
    end

    it 'has a Image for SSO Page image file upload' do
      expect(rendered).to have_selector('input[type="file"][name="identity_provider[logo_image]"]')
    end

    it 'has a Alt Text for Image text field' do
      expect(rendered).to have_selector('textarea[name="identity_provider[logo_image_text]"]')
    end

    it 'has a Save button' do
      expect(rendered).to have_selector('input[type="submit"][value="Save"]')
    end

    it 'does not display a Delete button for new records' do
      expect(rendered).not_to have_link('Delete')
    end

    it 'displays documentation section' do
      expect(rendered).to have_selector('h4', text: 'Documentation')
      expect(rendered).to have_text('Documentation for each identity provider type can be found in its associated adapter documentation.')
      expect(rendered).to have_link('SAML', href: 'https://github.com/omniauth/omniauth-saml')
      expect(rendered).to have_link('CAS', href: 'https://github.com/dlindahl/omniauth-cas')
      expect(rendered).to have_link('Openid Connect', href: 'https://github.com/omniauth/omniauth_openid_connect')
      expect(rendered).to have_link('Single Sign On (SSO)', href: 'https://samvera.atlassian.net/wiki/spaces/hyku/pages/3570663437/Identity+Provider+Single+Sign-On+SSO')
    end

    it 'displays message about assertion_consumer_service_url for new records' do
      expect(rendered).to have_text('SAML assertion_consumer_service_url will be displayed after the record is saved.')
    end

    it 'does not display Assertion Consumer Service URL for new records' do
      expect(rendered).not_to have_text('assertion consumer service URLs or redirect URLs')
    end

    it 'includes accessibility attributes on external links' do
      expect(rendered).to have_selector('a[target="_blank"][rel="noopener noreferrer"]', count: 5)
    end
  end

  # a form that gets submitted without Name or Provider should display validation errors
  context 'when form submission fails with validation errors' do
    let(:identity_provider) { IdentityProvider.new }

    before do
      assign(:identity_provider, identity_provider)
      # simulate errors by validating the model which sets up errors.messages and errors.details
      identity_provider.valid?
      # the form uses errors.details[key].first[:value] to display the error message
      details_hash = {
        name: [{ error: :blank, value: "" }],
        provider: [{ error: :blank, value: "" }]
      }
      allow(identity_provider.errors).to receive(:details).and_return(details_hash)
      render
    end

    it 'displays the error explanation section with error messages' do
      expect(rendered).to have_selector('#error_explanation h2', text: /2 errors prohibited this authentication provider from being saved/)
      expect(rendered).to have_selector('#error_explanation ul li', count: 2)
    end

    it 'displays error message for blank name' do
      # The form shows: name "" can't be blank
      expect(rendered).to have_selector('#error_explanation li', text: /name.*can't be blank/i)
    end

    it 'displays error message for blank provider' do
      # The form shows: provider "" can't be blank
      expect(rendered).to have_selector('#error_explanation li', text: /provider.*can't be blank/i)
    end
  end

  # a saved form should display the Name, Provider, assertion consumer service URLs, metadata link, and delete button
  context 'after saving a new identity provider' do
    let(:domain_name) { instance_double('DomainName', cname: 'hyku-me.test') }
    let(:account) { instance_double('Account', domain_names: [domain_name]) }
    # stub a created identity provider with an id
    let(:identity_provider) { build_stubbed(:identity_provider, id: 1) }
    let(:provider_collection) { Devise.omniauth_providers.map { |o| [o, o.upcase] } }

    before do
      assign(:identity_provider, identity_provider)
      assign(:current_account, account)
      assign(:provider_collection, provider_collection)
      render
    end

    it 'displays the existing Name and Provider values' do
      expect(rendered).to have_selector("input[name='identity_provider[name]'][value='#{identity_provider.name}']")
      expect(rendered).to have_selector("select[name='identity_provider[provider]'] option[value='#{identity_provider.provider}'][selected]")
    end

    it 'displays callback URLs for existing records' do
      expect(rendered).to have_text('assertion consumer service URLs or redirect URLs')
      expect(rendered).to have_text('hyku-me.test/users/auth/saml/1/callback')
    end

    it 'displays metadata link for existing records' do
      expect(rendered).to have_link('View metadata', href: '/users/auth/saml/1/metadata')
    end

    it 'does not display message about assertion_consumer_service_url for existing records' do
      expect(rendered).not_to have_text('SAML assertion_consumer_service_url will be displayed after the record is saved.')
    end

    it 'displays Delete button' do
      expect(rendered).to have_link('Delete')
    end

    it 'has a Save changes button' do
      expect(rendered).to have_selector('input[type="submit"]')
    end
  end

  # a saved form with a logo image should display the logo image and alt text
  context 'after saving a new identity provider with a logo image' do
    let(:domain_name) { instance_double('DomainName', cname: 'hyku-me.test') }
    let(:account) { instance_double('Account', domain_names: [domain_name]) }
    # stub a created identity provider with an id
    let(:identity_provider) { build_stubbed(:identity_provider, id: 1) }

    before do
      assign(:identity_provider, identity_provider)
      assign(:current_account, account)
      allow(identity_provider).to receive(:logo_image?).and_return(true)
      allow(identity_provider).to receive(:logo_image).and_return(double(url: '/path/to/image.jpg'))
      allow(identity_provider).to receive(:logo_image_text).and_return('Alt text')
      render
    end

    it 'displays the logo image in the form' do
      expect(rendered).to have_selector('img[src="/path/to/image.jpg"]')
    end

    it 'displays the alt text in the form' do
      expect(rendered).to have_selector('textarea[name="identity_provider[logo_image_text]"]', text: 'Alt text')
    end
  end

  # a saved form with options JSON should display the options as JSON in the textarea
  context 'after saving a new identity provider with options JSON' do
    let(:domain_name) { instance_double('DomainName', cname: 'hyku-me.test') }
    let(:account) { instance_double('Account', domain_names: [domain_name]) }
    # stub a created identity provider with JSON options
    let(:identity_provider) { build_stubbed(:identity_provider, id: 1, options: { 'sp_entity_id' => 'hyku-me.test/users/auth/saml/sp' }) }

    before do
      assign(:identity_provider, identity_provider)
      assign(:current_account, account)
      render
    end

    it 'displays the options as JSON in the textarea' do
      expect(rendered).to have_selector('textarea[name="identity_provider[options]"]')
      expect(rendered).to have_text('sp_entity_id')
    end
  end
end
