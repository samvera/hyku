# frozen_string_literal: true

class CatalogController < ApplicationController
  include BlacklightAdvancedSearch::Controller
  include BlacklightRangeLimit::ControllerOverride
  include Hydra::Catalog
  include Hydra::Controller::ControllerBehavior
  include BlacklightOaiProvider::Controller

  # These before_action filters apply the hydra access controls
  before_action :enforce_show_permissions, only: :show

  def self.created_field
    'date_created_ssim'
  end

  def self.creator_field
    'creator_ssim'
  end

  def self.modified_field
    'system_modified_dtsi'
  end

  def self.title_field
    'title_ssim'
  end

  def self.uploaded_field
    'system_create_dtsi'
  end

  # CatalogController-scope behavior and configuration for BlacklightIiifSearch
  include BlacklightIiifSearch::Controller

  configure_blacklight do |config|
    # IiifPrint index fields
    config.add_index_field 'all_text_timv'
    config.add_index_field 'file_set_text_tsimv', label: "Item contents", highlight: true, helper_method: :render_ocr_snippets

    # configuration for Blacklight IIIF Content Search
    config.iiif_search = {
      full_text_field: 'all_text_tsimv',
      object_relation_field: 'is_page_of_ssim',
      supported_params: %w[q page],
      autocomplete_handler: 'iiif_suggest',
      suggester_name: 'iiifSuggester'
    }

    config.view.gallery.partials = %i[index_header index]
    config.view.masonry.partials = [:index]
    config.view.slideshow.partials = [:index]

    config.show.tile_source_field = :content_metadata_image_iiif_info_ssm
    config.show.partials.insert(1, :openseadragon)
    # default advanced config values
    config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
    # config.advanced_search[:qt] ||= 'advanced'
    config.advanced_search[:url_key] ||= 'advanced'
    config.advanced_search[:query_parser] ||= 'dismax'
    config.advanced_search[:form_solr_parameters] ||= {}
    config.advanced_search[:form_facet_partial] ||= "advanced_search_facets_as_select"

    config.search_builder_class = IiifPrint::CatalogSearchBuilder

    # Use locally customized AdvSearchBuilder so we can enable blacklight_advanced_search
    # TODO ROB config.search_builder_class = AdvSearchBuilder

    # Show gallery view
    config.view.gallery.partials = %i[index_header index]
    config.view.slideshow.partials = [:index]

    # Because too many times on Samvera tech people raise a problem regarding a failed query to SOLR.
    # Often, it's because they inadvertently exceeded the character limit of a GET request.
    config.http_method = :post

    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
      qt: "search",
      rows: 10,
      qf: IiifPrint.config.metadata_fields.keys.map { |attribute| "#{attribute}_tesim" }
                   .join(' ') << " title_tesim description_tesim all_text_timv file_set_text_tsimv", # the first space character is necessary!
      "hl": true,
      "hl.simple.pre": "<span class='highlight'>",
      "hl.simple.post": "</span>",
      "hl.snippets": 30,
      "hl.fragsize": 100
    }

    # Specify which field to use in the tag cloud on the homepage.
    # To disable the tag cloud, comment out this line.
    config.tag_cloud_field_name = 'tag_sim'

    # solr field configuration for document/show views
    config.index.title_field = 'title_tesim'
    config.index.display_type_field = 'has_model_ssim'
    config.index.thumbnail_field = 'thumbnail_path_ss'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    config.add_facet_field 'human_readable_type_sim', label: "Type", limit: 5
    config.add_facet_field 'resource_type_sim', label: "Resource Type", limit: 5
    config.add_facet_field 'creator_sim', limit: 5
    config.add_facet_field 'contributor_sim', label: "Contributor", limit: 5
    config.add_facet_field 'keyword_sim', limit: 5
    config.add_facet_field 'subject_sim', limit: 5
    config.add_facet_field 'language_sim', limit: 5
    config.add_facet_field 'based_near_label_sim', limit: 5
    config.add_facet_field 'publisher_sim', limit: 5
    config.add_facet_field 'file_format_sim', limit: 5
    config.add_facet_field 'member_of_collections_ssim', limit: 5, label: 'Collections'

    # TODO: deal with part of facet changes
    # config.add_facet_field solr_name("part", :facetable), limit: 5, label: 'Part'
    # config.add_facet_field solr_name("part_of", :facetable), limit: 5
    # removed # config.add_facet_field solr_name("file_format", :facetable), limit: 5
    # removed # config.add_facet_field solr_name("contributor", :facetable), label: "Contributor", limit: 5
    # remvode config.add_facet_field solr_name("refereed", :facetable), limit: 5

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # TODO: ROB
    #     # Prior to this change, the applications specific translations were not loaded. Dogbiscuits were assuming the translations were already loaded.
    #     Rails.root.glob("config/locales/*.yml").each do |path|
    #       I18n.load_path << path.to_s
    #     end
    #     I18n.backend.reload!
    #     index_props = DogBiscuits.config.index_properties.collect do |prop|
    #       { prop => index_options(prop, DogBiscuits.config.property_mappings[prop]) }
    #     end
    #     add_index_field config, index_props

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    # show_props = DogBiscuits.config.all_properties
    # add_show_field config, show_props

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field 'title_tesim', label: "Title", itemprop: 'name', if: false
    config.add_index_field 'description_tesim', itemprop: 'description', helper_method: :iconify_auto_link
    config.add_index_field 'keyword_tesim', itemprop: 'keywords', link_to_search: 'keyword_sim'
    config.add_index_field 'subject_tesim', itemprop: 'about', link_to_search: 'subject_sim'
    config.add_index_field 'creator_tesim', itemprop: 'creator', link_to_search: 'creator_sim'
    config.add_index_field 'contributor_tesim', itemprop: 'contributor', link_to_search: 'contributor_sim'
    config.add_index_field 'proxy_depositor_ssim', label: "Depositor", helper_method: :link_to_profile
    config.add_index_field 'depositor_tesim', label: "Owner", helper_method: :link_to_profile
    config.add_index_field 'publisher_tesim', itemprop: 'publisher', link_to_search: 'publisher_sim'
    config.add_index_field 'based_near_label_tesim', itemprop: 'contentLocation', link_to_search: 'based_near_label_sim'
    config.add_index_field 'language_tesim', itemprop: 'inLanguage', link_to_search: 'language_sim'
    config.add_index_field 'date_uploaded_dtsi', itemprop: 'datePublished', helper_method: :human_readable_date
    config.add_index_field 'date_modified_dtsi', itemprop: 'dateModified', helper_method: :human_readable_date
    config.add_index_field 'date_created_tesim', itemprop: 'dateCreated'
    config.add_index_field 'rights_statement_tesim', helper_method: :rights_statement_links
    config.add_index_field 'license_tesim', helper_method: :license_links
    config.add_index_field 'resource_type_tesim', label: "Resource Type", link_to_search: 'resource_type_sim'
    config.add_index_field 'file_format_tesim', link_to_search: 'file_format_sim'
    config.add_index_field 'identifier_tesim', helper_method: :index_field_link, field_name: 'identifier'
    config.add_index_field 'embargo_release_date_dtsi', label: "Embargo release date", helper_method: :human_readable_date
    config.add_index_field 'lease_expiration_date_dtsi', label: "Lease expiration date", helper_method: :human_readable_date

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field 'title_tesim'
    config.add_show_field 'description_tesim'
    config.add_show_field 'keyword_tesim'
    config.add_show_field 'subject_tesim'
    config.add_show_field 'creator_tesim'
    config.add_show_field 'contributor_tesim'
    config.add_show_field 'publisher_tesim'
    config.add_show_field 'based_near_label_tesim'
    config.add_show_field 'language_tesim'
    config.add_show_field 'date_uploaded_tesim'
    config.add_show_field 'date_modified_tesim'
    config.add_show_field 'date_created_tesim'
    config.add_show_field 'rights_statement_tesim'
    config.add_show_field 'license_tesim'
    config.add_show_field 'resource_type_tesim', label: "Resource Type"
    config.add_show_field 'format_tesim'
    config.add_show_field 'identifier_tesim'
    config.add_show_field 'extent_tesim'

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.
    #
    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.
    config.add_search_field('all_fields', label: 'All Fields', include_in_advanced_search: false) do |field|
      all_names = config.show_fields.values.map(&:field).join(" ")
      # TODO: ROB all_names = (config.show_fields.values.map { |v| v.field.to_s } +
      #         DogBiscuits.config.all_properties.map { |p| "#{p}_tesim" }).uniq.join(" ")
      title_name = 'title_tesim'
      field.solr_parameters = {
        qf: "#{all_names} file_format_tesim all_text_timv",
        pf: title_name.to_s
      }
    end

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.
    # creator, title, description, publisher, date_created,
    # subject, language, resource_type, format, identifier, based_near,
    config.add_search_field('contributor') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params.
      field.solr_parameters = { "spellcheck.dictionary": "contributor" }

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      solr_name = 'contributor_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('creator') do |field|
      # TODO: ROB field.label = "Author"
      field.solr_parameters = { "spellcheck.dictionary": "creator" }
      solr_name = 'creator_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('title') do |field|
      field.solr_parameters = {
        "spellcheck.dictionary": "title"
      }
      solr_name = 'title_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('description') do |field|
      field.label = "Abstract or Summary"
      field.solr_parameters = {
        "spellcheck.dictionary": "description"
      }
      solr_name = 'description_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('publisher') do |field|
      field.solr_parameters = {
        "spellcheck.dictionary": "publisher"
      }
      solr_name = 'publisher_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    date_fields = ['date_created_tesim', 'sorted_date_isi', 'sorted_month_isi']

    config.add_search_field('date_created') do |field|
      field.solr_parameters = {
        "spellcheck.dictionary": "date_created"
      }
      field.solr_local_parameters = {
        qf: date_fields.join(' '),
        pf: date_fields.join(' ')
      }
    end

    config.add_search_field('subject') do |field|
      field.solr_parameters = {
        "spellcheck.dictionary": "subject"
      }
      solr_name = 'subject_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('language') do |field|
      field.solr_parameters = {
        "spellcheck.dictionary": "language"
      }
      solr_name = 'language_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('resource_type') do |field|
      field.solr_parameters = {
        "spellcheck.dictionary": "resource_type"
      }
      solr_name = 'resource_type_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('format') do |field|
      field.include_in_advanced_search = false
      field.solr_parameters = {
        "spellcheck.dictionary": "format"
      }
      solr_name = 'format_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('identifier') do |field|
      field.include_in_advanced_search = false
      field.solr_parameters = {
        "spellcheck.dictionary": "identifier"
      }
      solr_name = 'id_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('based_near_label') do |field|
      field.label = "Location"
      field.solr_parameters = {
        "spellcheck.dictionary": "based_near_label"
      }
      solr_name = 'based_near_label_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('keyword') do |field|
      field.solr_parameters = {
        "spellcheck.dictionary": "keyword"
      }
      solr_name = 'keyword_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('depositor') do |field|
      solr_name = 'depositor_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('rights_statement') do |field|
      solr_name = 'rights_statement_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('license') do |field|
      solr_name = 'license_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('extent') do |field|
      solr_name = 'extent_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('source') do |field|
      solr_name = solr_name("source", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    # label is key, solr field is value
    config.add_sort_field "score desc, #{uploaded_field} desc", label: "Relevance"

    config.add_sort_field "#{title_field} asc", label: "Title"
    config.add_sort_field "#{creator_field} asc", label: "Author"
    config.add_sort_field "#{created_field} asc", label: "Published Date (Ascending)"
    config.add_sort_field "#{created_field} desc", label: "Published Date (Descending)"
    config.add_sort_field "#{modified_field} asc", label: "Upload Date (Ascending)"
    config.add_sort_field "#{modified_field} desc", label: "Upload Date (Descending)"

    # OAI Config fields
    config.oai = {
      provider: {
        repository_name: ->(controller) { controller.send(:current_account)&.name.presence },
        # repository_url:  ->(controller) { controller.oai_catalog_url },
        record_prefix: ->(controller) { controller.send(:current_account).oai_prefix },
        admin_email:   ->(controller) { controller.send(:current_account).oai_admin_email },
        sample_id:     ->(controller) { controller.send(:current_account).oai_sample_identifier }
      },
      document: {
        limit: 100, # number of records returned with each request, default: 15
        set_fields: [ # ability to define ListSets, optional, default: nil
          { label: 'collection', solr_field: 'isPartOf_ssim' }
        ]
      }
    }

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
  end

  # This is overridden just to give us a JSON response for debugging.
  def show
    _, @document = fetch params[:id]
    render json: @document.to_h
  end
end
