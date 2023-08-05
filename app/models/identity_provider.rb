class IdentityProvider < ApplicationRecord

  def parsed_options(rack_env = nil)
    @parsed_options = options.with_indifferent_access
    return @parsed_options unless provider == 'saml'
    @parsed_options['assertion_consumer_service_url'] = "#{rack_env['HTTP_X_FORWARDED_PROTO']}://#{rack_env['HTTP_HOST']}/users/auth/saml/#{self.id}/callback"
    return @parsed_options unless @parsed_options['idp_metadata_url']
    idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new
    idp_metadata = idp_metadata_parser.parse_remote_to_hash(@parsed_options['idp_metadata_url'])
    @paresd_options = idp_metadata.merge(@parsed_options)
  end
end
