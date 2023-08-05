Rails.application.config.middleware.insert_after ActionDispatch::Session::CookieStore, Rack::Saml,
  {:config => "#{Rails.root}/config/shibboleth/rack-saml.yml",
    :metadata => "#{Rails.root}/config/shibboleth/metadata.yml",
    :attribute_map => "#{Rails.root}/config/shibboleth/attribute-map.yml"}
