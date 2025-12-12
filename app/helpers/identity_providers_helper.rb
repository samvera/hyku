# frozen_string_literal: true

module IdentityProvidersHelper
  def external_link_attrs
    {
      target: '_blank',
      rel: 'noopener noreferrer'
    }
  end

  def samvera_docs_url
    'https://samvera.atlassian.net/wiki/spaces/hyku/pages/3570663437/Identity+Provider+Single+Sign-On+SSO'
  end

  def saml_docs_url
    'https://github.com/omniauth/omniauth-saml#idp-metadata'
  end

  def adapter_documentation_links
    [
      {
        name: t('hyku.identity_provider.documentation.link.saml'),
        url: 'https://github.com/omniauth/omniauth-saml',
        aria_label: t('hyku.identity_provider.documentation.aria_label.saml')
      },
      {
        name: t('hyku.identity_provider.documentation.link.cas'),
        url: 'https://github.com/dlindahl/omniauth-cas',
        aria_label: t('hyku.identity_provider.documentation.aria_label.cas')
      },
      {
        name: t('hyku.identity_provider.documentation.link.openid_connect'),
        url: 'https://github.com/omniauth/omniauth_openid_connect',
        aria_label: t('hyku.identity_provider.documentation.aria_label.openid_connect')
      }
    ]
  end

  def saml_callback_path(identity_provider)
    "/users/auth/saml/#{identity_provider.id}/callback"
  end

  def saml_metadata_path(identity_provider)
    "/users/auth/saml/#{identity_provider.id}/metadata"
  end
end
