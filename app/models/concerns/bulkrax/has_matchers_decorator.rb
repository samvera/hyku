# frozen_string_literal: true

# OVERRIDE Bulkrax v5.3.0 to add a geonames lookup for the `based_near` proprerty

module Bulkrax
  module HasMatchersDecorator
    ##
    # @note We likely want to extract something like this to Bulkrax.
    #       However, we probably cannot assume that we have a field named
    #       `based_near` that is in fact the Location field.
    #
    #       On possibility is to have a Hash that has key of :name and value
    #       of a lambda; that Lambdawould receive the given :result and return
    #       the correct value.  As we can see in the implementation below, we
    #       need to consider the `Site.instance` which is a Hyku specific
    #       consideration.
    def matched_metadata(multiple, name, result, object_multiple)
      if name == 'based_near'
        return result if result.blank?

        result = result.join if result.is_a?(Array)
        result = if result.start_with?('http')
                   Hyrax::ControlledVocabularies::Location.new(RDF::URI.new(result))
                 else
                   geonames_lookup(result)
                 end
      end
      super
    end

    private

    def geonames_lookup(result)
      geonames_username = ::Site.instance.account.geonames_username
      return nil unless geonames_username

      base_url = 'http://api.geonames.org/searchJSON'
      params = { q: result, maxRows: 10, username: geonames_username }
      uri = URI(base_url)
      uri.query = URI.encode_www_form(params)

      response = Net::HTTP.get_response(uri)
      data = JSON.parse(response.body)

      return if data.blank?

      raise 'Invalid user. Check that geonames_username is set in the Site instance Account settings' if data.fetch('status', {})['message'] == 'invalid user'

      geoname = data['geonames'].first

      unless geoname
        uri = URI::HTTP.build(host: 'fake', fragment: result)
        return Hyrax::ControlledVocabularies::Location.new(RDF::URI.new(uri))
      end

      # Create a Hyrax::ControlledVocabularies::Location object with the RDF subject
      rdf_subject = RDF::URI.new("https://sws.geonames.org/#{geoname['geonameId']}/")
      Hyrax::ControlledVocabularies::Location.new(rdf_subject)
    end
  end
end

# Prepending this to `Bulkrax::HasMatchers` yielded an unbound method
# Thus, I am prepending it to `Bulkrax::Entry` since that mixes in `Bulkrax::HasMatchers`
Bulkrax::Entry.prepend(Bulkrax::HasMatchersDecorator)
