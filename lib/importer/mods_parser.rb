module Importer
  # rubocop:disable Metrics/ClassLength
  class ModsParser
    NAMESPACES = { 'mods'.freeze => Mods::MODS_NS }.freeze

    attr_reader :filename

    def initialize(filename)
      @filename = filename
    end

    def model
      @model ||= if collection?
                   Collection
                 elsif image?
                   'Image'
                 else
                   'ETD'
                 end
    end

    def origin_text
      'Converted from MODS 3.4 to local RDF profile by Hyku'.freeze
    end

    def mods
      @mods ||= Mods::Record.new.from_file(filename)
    end

    def collection?
      type_keys = mods.typeOfResource.attributes.map(&:keys).flatten
      return false unless type_keys.include?('collection')
      mods.typeOfResource.attributes.any? { |hash| hash.fetch('collection').value == 'yes' }
    end

    # For now the only things we import are collections and
    # images, so if it's not a collection, assume it's an image.
    # TODO:  Identify images or other record types based on
    #        the data in <mods:typeOfResource>.
    def image?
      !collection?
    end

    def attributes
      if model == Collection
        collection_attributes
      else
        record_attributes
      end
    end

    def record_attributes
      common_attributes.merge(collection: collection, series_name: series_name)
                       .merge(files)
    end

    # @return [Hash] hash with a key :files, if there are any files.
    def files
      {}
    end

    def series_name
      mods.xpath("//mods:relatedItem[@type='series']", NAMESPACES)
          .titleInfo.title.map(&:text)
    end

    def collection_attributes
      common_attributes
    end

    def common_attributes
      description
        .merge(dates)
        .merge(locations)
        .merge(rights)
        .merge(identifiers)
        .merge(relations)
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def description
      {
        title: untyped_title,
        alternative: alt_title,
        description: mods_description,
        subject: subject,
        extent: mods.physical_description.extent.map { |node| strip_whitespace(node.text) },
        language: language,
        digital_origin: mods.physical_description.digitalOrigin.map(&:text),
        publisher: mods.origin_info.publisher.map(&:text),
        form_of_work: mods.genre.valueURI.map { |uri| RDF::URI.new(uri) },
        resource_type: resource_type,
        citation: citation,
        notes_attributes: notes,
        record_origin: record_origin,
        description_standard: mods.record_info.descriptionStandard.map(&:text)
      }
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    def language
      mods.language.languageTerm.map do |term|
        uris = term.valueURI.map { |uri| RDF::URI.new(uri) }
        uris.presence || term.text
      end
    end

    def resource_type
      uris = mods.xpath('//mods:mods/mods:typeOfResource/@valueURI', NAMESPACES).map { |uri| RDF::URI.new(uri.value) }
      return uris if uris.present?
      Array.wrap(mods.typeOfResource.text)
    end

    def rights
      query = '/mods:mods/mods:accessCondition[@type="use and reproduction"]'.freeze
      {
        restrictions: mods.xpath(query, NAMESPACES).map { |node| strip_whitespace(node.text) }
      }
    end

    def locations
      {
        location: mods.subject.geographic.valueURI.map { |uri| RDF::URI.new(uri) },
        sub_location: sub_location,
        institution: institutional_location,
        place_of_publication: mods.origin_info.place.placeTerm.map(&:text)
      }.merge(coordinates)
    end

    def sub_location
      query = './mods:copyInformation/mods:subLocation'.freeze
      mods.location.holdingSimple.xpath(query, NAMESPACES).map(&:text)
    end

    def institutional_location
      uris = mods.location.physicalLocation.valueURI.map { |uri| RDF::URI.new(uri) }
      return uris if uris.present?
      Array.wrap(mods.location.physicalLocation.text)
    end

    # rubocop:disable Metrics/AbcSize
    def dates
      {
        issued_attributes: build_date(mods.origin_info.dateIssued),
        created_attributes: build_date(mods.origin_info.dateCreated),
        date_other_attributes: build_date(mods.origin_info.dateOther),
        date_copyrighted_attributes: build_date(mods.origin_info.copyrightDate),
        date_valid_attributes: build_date(mods.origin_info.dateValid)
      }
    end
    # rubocop:enable Metrics/AbcSize

    def identifiers
      { accession_number: mods.identifier.map(&:text) }
    end

    def record_origin
      ro = mods.record_info.recordOrigin.map { |node| prepend_timestamp(strip_whitespace(node.text)) }
      ro << prepend_timestamp(origin_text)
    end

    # returns a hash with :latitude and :longitude
    def coordinates
      coords = mods.subject.cartographics.coordinates.map(&:text)
      # a hash where any value defaults to an empty array
      result = Hash.new { |h, k| h[k] = [] }
      coords.each_with_object(result) do |coord, h|
        (latitude, longitude) = coord.split(/,\s*/)
        h[:latitude] << latitude
        h[:longitude] << longitude
      end
    end

    def mods_description
      mods.abstract.map { |e| strip_whitespace(e.text) }
    end

    def relations
      name_nodes = mods.xpath('//mods:mods/mods:name'.freeze, NAMESPACES)
      # TODO: do we want all sorts of relators?
      # property_name_for_uri = Metadata::MARCREL.invert
      name_nodes.each_with_object({}) do |node, relations|
        # property = if value_uri = node.role.roleTerm.valueURI.first
        #              property_name_for_uri[RDF::URI(value_uri)]
        #            else
        #              $stderr.puts "no role was specified for name #{node.namePart.text}"
        #              :contributor
        # end
        property = :contributor
        relations[property] ||= []
        relations[property] << build_relation(node)
      end
    end

    def build_relation(node)
      uri = node.attributes['valueURI']
      if uri.blank?
        { name: node.namePart.map(&:text),
          type: node.attributes['type'].value }
      else
        RDF::URI.new(uri)
      end
    end

    def collection
      {
        identifier: collection_id,
        title: collection_name
      }
    end

    def collection_name
      node_set = mods.at_xpath("//mods:relatedItem[@type='host']".freeze, NAMESPACES)
      return unless node_set
      [node_set.titleInfo.title.text.strip]
    end

    def collection_id
      query = "//mods:relatedItem[@type='host']/mods:identifier[@type='uri']".freeze
      node_set = mods.at_xpath(query, NAMESPACES)
      return [] unless node_set
      Array.wrap(node_set.text)
    end

    # Remove multiple whitespace
    def citation
      mods.xpath('//mods:note[@type="preferred citation"]'.freeze, NAMESPACES).map do |node|
        node.text.gsub(/\n\s+/, "\n")
      end
    end

    # rubocop:disable Metrics/AbcSize
    def notes
      preferred_citation = 'preferred citation'.freeze
      type = 'type'.freeze
      mods.note.each_with_object([]) do |node, list|
        next if node.attributes.key?(type) && node.attributes[type].value == preferred_citation
        hash = { value: node.text.gsub(/\n\s+/, "\n") }
        type_attr = node.attributes[type].try(:text)
        hash[:note_type] = type_attr if type_attr
        list << hash
      end
    end
    # rubocop:enable Metrics/AbcSize

    private

      def build_date(node)
        finish = finish_point(node)
        start = start_point(node)
        dates = [{ start: start.map(&:text), finish: finish.map(&:text), label: date_label(node),
                   start_qualifier: qualifier(start), finish_qualifier: qualifier(finish) }]
        dates.delete_if { |date| date.values.all?(&:blank?) }
        dates
      end

      def qualifier(nodes)
        nodes.map { |node| node.attributes['qualifier'].try(:value) }.compact
      end

      def finish_point(node)
        node.css('[point="end"]')
      end

      def start_point(node)
        node.css("[encoding]:not([point='end'])".freeze)
      end

      def date_label(node)
        node.css(':not([encoding])'.freeze).map(&:text)
      end

      def untyped_title
        mods.xpath('/mods:mods/mods:titleInfo[not(@type)]/mods:title', NAMESPACES).map(&:text)
      end

      def alt_title
        Array(mods.xpath('//mods:titleInfo[@type]', NAMESPACES)).flat_map do |node|
          type = node.attributes['type'].text
          alternative = 'alternative'.freeze

          node.title.map do |title|
            value = title.text
            warn_title_transform(type, value) unless type == alternative
            value
          end
        end
      end

      def warn_title_tranform(type, value)
        Rails.logger.warn "Transformtion: \"#{type} title\" will be stored as \"alternative title\": #{value}"
      end

      def prepend_timestamp(text)
        "#{Time.now.utc.to_s(:iso8601)} #{text}"
      end

      def strip_whitespace(text)
        text.tr("\n", ' ').delete("\t")
      end

      def subject
        query = '//mods:subject/mods:name/@valueURI|//mods:subject/mods:topic/@valueURI'
        uris = mods.xpath(query, NAMESPACES).map { |uri| RDF::URI.new(uri) }
        return uris unless uris.empty?
        mods.subject.map do |sub|
          text = sub.css('name namePart').text
          secondary = sub.css('topic,genre').text
          text += " -- #{secondary}" if secondary.present?
          text
        end
      end
  end
  # rubocop:enable Metrics/ClassLength
end
