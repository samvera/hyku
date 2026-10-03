# frozen_string_literal: true

module Hyku
  ##
  # Builds IIIF v3 metadata from the m3 profile's view definitions, rendering each
  # value through the same presenter and renderer the show page uses, so a
  # controlled term shows its label and a faceted value links to its facet.
  #
  # The manifest is cached publicly, so fields are chosen and rendered as an
  # anonymous visitor would see them, whoever requested it.
  class ProfileManifestMetadata
    LEADING_FIELDS = [[:title], [:description, :abstract]].freeze
    SKIPPED_FIELDS = [:admin_note].freeze

    # Whether a work's manifest metadata comes from its profile: flexible metadata
    # is on, and the work was indexed under a profile. Hyku's show page gates on
    # the same switch, so turning it off restores IiifPrint's metadata everywhere.
    def self.applies_to?(document)
      Hyrax.config.flexible? && document.try(:flexible?).present?
    end

    # @param definitions [Hash] view definitions by schema, shared across the
    #   records of one manifest so a large work does not re-read the profile per page
    def self.for_work(document, base_url:, definitions: {})
      new(document, base_url:, definitions:).work_metadata
    end

    def self.for_file_set(document, base_url:, definitions: {})
      new(document, base_url:, definitions:).metadata
    end

    def initialize(document, base_url:, definitions: {})
      @document = document
      @base_url = base_url
      @definitions = definitions
    end

    ##
    # The show page's own helpers, called without a request: as an anonymous
    # visitor, in the current I18n locale.
    class AnonymousView
      include ActionView::Helpers::TranslationHelper
      include Blacklight::ConfigurationHelperBehavior
      include Hyrax::AttributesHelper

      def locale
        I18n.locale
      end

      def current_user; end
    end

    def work_metadata
      leading = LEADING_FIELDS.filter_map { |candidates| candidates.find { |field| leading_options.key?(field) } }
      leading.filter_map { |field| entry_for(field, leading_options[field]) } +
        collection_entries +
        metadata(except: leading)
    end

    def metadata(except: [])
      view_definitions.except(*except).filter_map do |field, options|
        entry_for(field, options) unless SKIPPED_FIELDS.include?(field)
      end
    end

    private

    attr_reader :document, :base_url, :definitions

    # Mirrors the flexible branch of the show page's attribute rows.
    def entry_for(field, options)
      # A shallow copy: conform_options changes only top-level keys, and
      # sparql's Hash#deep_dup would drop the indifferent access it reads by.
      view_options = view.conform_options(field, options.dup)
      # No presenter: an anonymous visitor is never an editor. Featured fields
      # count as visible because the show page renders them above its rows.
      return unless view.field_visible?(view_options.except(:position), nil)

      values = rendered_values(view.conform_field(field, options), view_options)
      return if values.empty?

      { 'label' => { I18n.locale.to_s => [view_options[:label]] }, 'value' => { 'none' => values } }
    end

    def rendered_values(field, options)
      html = presenter.attribute_to_html(field.to_sym, options.symbolize_keys.merge(html_dl: true))
      Nokogiri::HTML.fragment(html.to_s).css('dd > ul > li').map { |li| sanitize(separate_compound_entries(li).inner_html) }.compact_blank
    end

    def collection_entries
      return [] if document['member_of_collection_ids_ssim'].blank?

      collections = Hyrax::CollectionMemberService.run(document, anonymous_ability)
      return [] if collections.empty?

      links = collections.map { |c| %(<a href="#{File.join(base_url, 'collections', c.id)}">#{ERB::Util.h(c.title.first)}</a>) }
      [{ 'label' => { I18n.locale.to_s => [Hyrax::Renderers::AttributeRenderer.new(:collection, nil).label] },
         'value' => { 'none' => links } }]
    end

    # The compound renderer separates entries and sub-properties with divs,
    # which IIIF does not allow, so keep them apart as paragraphs and line breaks.
    def separate_compound_entries(node)
      node.css('.hyrax-compound-subproperty + .hyrax-compound-subproperty').each { |sub| sub.add_previous_sibling('<br>') }
      node.css('.hyrax-compound-subproperty').each { |sub| sub.name = 'span' }
      node.css('.hyrax-compound-entry').each { |entry| entry.name = 'p' }
      node
    end

    def sanitize(html)
      Hyku::IiifMetadataHtml.sanitize(html, base_url:)
    end

    # Title and description lead even without a view block (the show page renders
    # them outside its attribute rows, and view_definitions_for skips them). Read
    # from the schema's class map, which keys compound sub-properties by profile
    # key, so the `shared_title` sub-property cannot replace `title`. Falls back
    # to the latest profile when the named one is gone, as M3SchemaLoader does.
    def leading_options
      definitions[[:leading, schema_name, document.schema_version]] ||= begin
        schema = Hyrax::FlexibleSchema.find_by(id: document.schema_version) || Hyrax::FlexibleSchema.order(:created_at).last
        (schema&.attributes_for(schema_name) || {})
          .slice(*LEADING_FIELDS.flatten.map(&:to_s))
          .to_h { |name, config| [name.to_sym, Hyrax::SchemaLoader::AttributeDefinition.new(name, config).view_options] }
      end
    end

    def view_definitions
      definitions[[schema_name, document.schema_version, document.contexts]] ||=
        Hyrax::Schema.m3_schema_loader
                     .view_definitions_for(schema: schema_name, version: document.schema_version, contexts: document.contexts)
                     .transform_keys(&:to_sym)
    end

    def schema_name
      document.hydra_model.to_s
    end

    def presenter
      @presenter ||= if document.file_set?
                       Hyrax::FileSetPresenter.new(document, anonymous_ability)
                     else
                       Hyku::WorkShowPresenter.new(document, anonymous_ability)
                     end
    end

    def view
      @view ||= AnonymousView.new
    end

    def anonymous_ability
      @anonymous_ability ||= ::Ability.new(nil)
    end
  end
end
