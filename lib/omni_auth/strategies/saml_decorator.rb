# frozen_string_literal: true

# OVERRIDE OmniAuth v2.1.1

# monkey patch to support metadata paths - hacked version of:
#    https://github.com/salsify/omniauth-multi-provider/issues/4#issuecomment-366452170
#
# This patches omn-auth-saml to ensure setup_phase is called at the beginning of other_phase
# (which is consistent with how it handles request_phase and callback_phase).
module OmniAuth
  module Strategies
    module SamlDecorator
      def on_auth_path?
        # Override this to ensure initialization happens properly in OmniAuth::Strategies::SAML for "other"
        # requests
        current_path.start_with?(options.path_prefix)
      end

      def on_other_path?
        # Override this to ensure initialization happens properly in OmniAuth::Strategies::SAML for "other"
        # requests
        current_path.match(%r{/(?:metadata|spslo|slo)\z})
      end

      def other_phase
        # Override the other_phase method to call setup_phase before checking to see if the request
        # is on an "other" request path. This ensures omniauth-multi-provider has setup the path
        # prefix properly for the given identity provider. By default omniauth won't call setup_phase until
        # after checking the path.
        @callback_path = nil
        setup_phase if on_auth_path? && on_other_path?
        super
      end

      def request_path
        super
        @request_path = @request_path.gsub('saml/saml', 'saml')
      end

      def callback_path
        super
        @callback_path = @callback_path.gsub('saml/saml', 'saml')
      end

      def setup_path
        super
        @setup_path = @setup_path.gsub('saml/saml', 'saml')
      end

      def setup_phase
        # Make sure we only perform setup once since this method will be called twice during the other phase
        return if @setup # TODO: always false due to the calling class being created anew each time?
        super
        @setup = true
      end
    end
  end
end

OmniAuth::Strategies::SAML.prepend(OmniAuth::Strategies::SamlDecorator)
