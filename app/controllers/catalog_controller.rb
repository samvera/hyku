# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength, Metrics/BlockLength
class CatalogController < ApplicationController
  include BlacklightAdvancedSearch::Controller
  include BlacklightRangeLimit::ControllerOverride
  include Hydra::Catalog
  include Hydra::Controller::ControllerBehavior
  include BlacklightOaiProvider::Controller
  include Hyrax::FlexibleCatalogBehavior if Hyrax.config.flexible?

  # These before_action filters apply the hydra access controls
  before_action :enforce_show_permissions, only: :show
  after_action :cache_control, only: :index

  def self.created_field
    'date_created_ssi'
  end

  def self.creator_field
    'creator_ssi'
  end

  def self.modified_field
    'system_modified_dtsi'
  end

  def self.title_field
    'title_ssi'
  end

  def self.uploaded_field
    'system_create_dtsi'
  end

  # CatalogController-scope behavior and configuration for BlacklightIiifSearch
  include BlacklightIiifSearch::Controller

  configure_blacklight do |config|
    config.view.gallery(document_component: Blacklight::Gallery::DocumentComponent)
    config.view.masonry(document_component: Blacklight::Gallery::DocumentComponent)
    config.view.slideshow(document_component: Blacklight::Gallery::SlideshowComponent)

    # IiifPrint index fields
    config.add_index_field 'all_text_timv'
    config.add_index_field 'all_text_tsimv',
      label: "Item contents",
      highlight: true,
      helper_method: :render_ocr_snippets,
      values: ->(field_config, document, _context) { document.highlight_field(field_config.field).map(&:html_safe) if document.has_highlight_field? field_config.field }

    # configuration for Blacklight IIIF Content Search
    config.iiif_search = {
      full_text_field: 'all_text_tsimv',
      object_relation_field: 'is_page_of_ssim',
      supported_params: %w[q page],
      autocomplete_handler: 'iiif_suggest',
      suggester_name: 'iiifSuggester'
    }

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
    config.search_builder_class = AdvSearchBuilder

    # Show gallery view
    config.view.gallery.partials = %i[index_header index]
    config.view.masonry.partials = [:index]
    config.view.slideshow.partials = [:index]

    # Because too many times on Samvera tech people raise a problem regarding a failed query to SOLR.
    # Often, it's because they inadvertently exceeded the character limit of a GET request.
    config.http_method = :post

    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    #  Max fragsize is needed to not cut off full text search at default 51,000 characters
    config.default_solr_params = {
      qt: "search",
      rows: 10,
      qf: (
        IiifPrint.config.metadata_fields.keys.map { |attribute| "#{attribute}_tesim" } +
        ["title_tesim", "description_tesim", "all_text_timv", "all_text_tsimv"]
      ).uniq.join(' '),
      "hl": true,
      "hl.simple.pre": "<span class='highlight'>",
      "hl.simple.post": "</span>",
      "hl.snippets": 30,
      "hl.fragsize": 100,
      "hl.maxAnalyzedChars": 5_100_000
    }

    # Specify which field to use in the tag cloud on the homepage.
    # To disable the tag cloud, comment out this line.
    config.tag_cloud_field_name = 'tag_sim'

    # solr field configuration for document/show views
    config.index.title_field = 'title_tesim'
    config.index.display_type_field = 'has_model_ssim'
    config.index.thumbnail_field = 'thumbnail_path_ss'

    # Blacklight 7 additions
    config.add_results_document_tool(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
    config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)
    config.add_results_collection_tool(:view_type_group)
    config.add_show_tools_partial(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
    config.add_show_tools_partial(:email, callback: :email_action, validator: :validate_email_params)
    config.add_show_tools_partial(:sms, if: :render_sms_action?, callback: :sms_action, validator: :validate_sms_params)
    config.add_show_tools_partial(:citation)
    config.add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?)
    config.add_nav_action(:search_history, partial: 'blacklight/nav/search_history')

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    config.add_facet_field 'generic_type_sim', label: "Type", limit: 5
    config.add_facet_field 'resource_type_sim', label: "Resource Type", limit: 5
    config.add_facet_field 'creator_sim', limit: 5
    config.add_facet_field 'contributor_sim', label: "Contributor", limit: 5
    config.add_facet_field 'keyword_sim', limit: 5
    config.add_facet_field 'subject_sim', limit: 5
    config.add_facet_field 'language_sim', limit: 5
    config.add_facet_field 'based_near_label_sim', limit: 5
    config.add_facet_field 'publisher_sim', limit: 5
    config.add_facet_field 'file_format_sim', limit: 5
    config.add_facet_field 'contributing_library_sim', limit: 5
    config.add_facet_field 'member_of_collections_ssim', limit: 5, label: 'Collections'

    # TODO: deal with part of facet changes
    # config.add_facet_field 'part_sim', limit: 5, label: 'Part'
    # config.add_facet_field 'part_of_sim', limit: 5

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field 'title_tesim', label: "Title", itemprop: 'name', if: :render_in_tenant?
    config.add_index_field 'description_tesim', itemprop: 'description', helper_method: :truncate_and_iconify_auto_link, if: :render_in_tenant?
    config.add_index_field 'keyword_tesim', itemprop: 'keywords', link_to_facet: 'keyword_sim', if: :render_in_tenant?
    config.add_index_field 'subject_tesim', itemprop: 'about', link_to_facet: 'subject_sim', if: :render_in_tenant?
    config.add_index_field 'creator_tesim', itemprop: 'creator', link_to_facet: 'creator_sim', if: :render_in_tenant?
    config.add_index_field 'date_tesim', itemprop: 'date', if: :render_in_tenant?
    config.add_index_field 'contributor_tesim', itemprop: 'contributor', link_to_facet: 'contributor_sim', if: :render_in_tenant?
    config.add_index_field 'proxy_depositor_ssim', label: "Depositor", helper_method: :link_to_profile, if: :render_in_tenant?
    config.add_index_field 'depositor_tesim', label: "Owner", helper_method: :link_to_profile, if: :render_in_tenant?
    config.add_index_field 'publisher_tesim', itemprop: 'publisher', link_to_facet: 'publisher_sim', if: :render_in_tenant?
    config.add_index_field 'based_near_label_tesim', itemprop: 'contentLocation', link_to_facet: 'based_near_label_sim', if: :render_in_tenant?
    config.add_index_field 'language_tesim', itemprop: 'inLanguage', link_to_facet: 'language_sim', if: :render_in_tenant?
    config.add_index_field 'date_uploaded_dtsi', itemprop: 'datePublished', helper_method: :human_readable_date, if: :render_in_tenant?
    config.add_index_field 'date_modified_dtsi', itemprop: 'dateModified', helper_method: :human_readable_date, if: :render_in_tenant?
    config.add_index_field 'date_created_tesim', itemprop: 'dateCreated', if: :render_in_tenant?
    config.add_index_field 'rights_statement_tesim', helper_method: :rights_statement_links, if: :render_in_tenant?
    config.add_index_field 'license_tesim', helper_method: :license_links, if: :render_in_tenant?
    config.add_index_field 'resource_type_tesim', label: "Resource Type", link_to_facet: 'resource_type_sim', if: :render_in_tenant?
    config.add_index_field 'file_format_tesim', link_to_facet: 'file_format_sim', if: :render_in_tenant?
    config.add_index_field 'identifier_tesim', helper_method: :index_field_link, field_name: 'identifier', if: :render_in_tenant?
    config.add_index_field 'related_url_tesim', helper_method: :truncate_and_iconify_auto_link, if: :render_in_tenant?
    config.add_index_field 'embargo_release_date_dtsi', label: "Embargo release date", helper_method: :human_readable_date, if: :render_in_tenant?
    config.add_index_field 'lease_expiration_date_dtsi', label: "Lease expiration date", helper_method: :human_readable_date, if: :render_in_tenant?
    config.add_index_field 'learning_resource_type_tesim', label: "Learning resource type", if: :render_in_tenant?
    config.add_index_field 'education_level_tesim', label: "Education level", if: :render_in_tenant?
    config.add_index_field 'audience_tesim', label: "Audience", if: :render_in_tenant?
    config.add_index_field 'discipline_tesim', label: "Discipline", if: :render_in_tenant?

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field 'description_tesim', helper_method: :truncate_and_iconify_auto_link
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
    config.add_show_field 'rights_statement_tesim', helper_method: :rights_statement_links
    config.add_show_field 'license_tesim', helper_method: :license_links
    config.add_show_field 'resource_type_tesim', label: "Resource Type"
    config.add_show_field 'format_tesim'
    config.add_show_field 'identifier_tesim'
    config.add_show_field 'extent_tesim'
    config.add_show_field 'admin_note_tesim', label: "Administrative Notes"
    config.add_show_field "alternative_title_tesim", label: "Alternative title"
    config.add_show_field "related_url_tesim", helper_method: :truncate_and_iconify_auto_link
    config.add_show_field 'learning_resource_type_tesim'
    config.add_show_field 'education_level_tesim'
    config.add_show_field 'audience_tesim'
    config.add_show_field 'discipline_tesim'
    config.add_show_field "date_tesim", label: "Date", helper_method: :human_readable_date
    config.add_show_field "table_of_contents_tesim", label: "Table of contents"
    config.add_show_field "rights_holder_tesim", label: "Rights holder"
    config.add_show_field "additional_information_tesim", label: "Additional information"
    config.add_show_field "oer_size_tesim", label: "Size"
    config.add_show_field 'accessibility_feature_tesim'
    config.add_show_field 'accessibility_hazard_tesim'
    config.add_show_field 'accessibility_summary_tesim', label: "Accessibility summary"
    config.add_show_field 'previous_version_id_tesim'
    config.add_show_field 'newer_version_id_tesim'
    config.add_show_field 'related_item_id_tesim'
    config.add_show_field 'contributing_library_tesim'
    config.add_show_field 'library_catalog_identifier_tesim'
    config.add_show_field 'chronology_note_tesim'

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
      title_name = 'title_tesim'
      field.solr_parameters = {
        qf: "#{all_names} #{title_name} file_format_tesim all_text_tsimv all_text_tsimv",
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
      solr_name = 'source_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('advisor') do |field|
      solr_name = 'advisor_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('accessibility_feature') do |field|
      solr_name = 'accessibility_feature_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('accessibility_hazard') do |field|
      solr_name = 'accessibility_hazard_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('accessibility_summary') do |field|
      solr_name = 'accessibility_summary_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('additional_information') do |field|
      solr_name = 'additional_information_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('alternative_title') do |field|
      solr_name = 'alternative_title_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('audience') do |field|
      solr_name = 'audience_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('bibliographic_citation') do |field|
      solr_name = 'bibliographic_citation_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('committee_member') do |field|
      solr_name = 'committee_member_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('department') do |field|
      solr_name = 'department_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('degree_discipline') do |field|
      solr_name = 'degree_discipline_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('education_level') do |field|
      solr_name = 'education_level_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('degree_grantor') do |field|
      solr_name = 'degree_grantor_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('learning_resource_type') do |field|
      solr_name = 'learning_resource_type_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('degree_level') do |field|
      solr_name = 'degree_level_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('related_url') do |field|
      solr_name = 'related_url_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('rights_holder') do |field|
      solr_name = 'rights_holder_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('rights_notes') do |field|
      solr_name = 'rights_notes_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('size') do |field|
      solr_name = 'size_tesim'
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('table_of_contents') do |field|
      solr_name = 'table_of_contents_tesim'
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
        repository_url: ->(controller) { controller.oai_catalog_url.split('?locale').first }, # remove i18n for oai URL
        record_prefix: ->(controller) { controller.send(:current_account).oai_prefix },
        admin_email: ->(controller) { controller.send(:current_account).oai_admin_email },
        sample_id: ->(controller) { controller.send(:current_account).oai_sample_identifier }
      },
      document: {
        limit: 100, # number of records returned with each request, default: 15
        set_fields: [ # ability to define ListSets, optional, default: nil
          { label: 'admin_set', solr_field: 'isPartOf_ssim' },
          { label: 'collection', solr_field: 'member_of_collection_ids_ssim' }
        ]
      }
    }

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
  end

  # This is overridden just to give us a JSON response for debugging.
  def show
    _, @document = search_service.fetch(params[:id])
    render json: @document.to_h
  end

  # The styling is off when the bookmark checkbox renders, plus there's no way for a user to get
  # to the /bookmarks route anyway.  For now we're following Hyrax's opinion and turning it off.
  #
  # https://github.com/samvera/hyrax/blob/abeb5aff99d8ff6a7d32f6e8234538d7bef15fbd/.dassie/app/controllers/catalog_controller.rb#L304-L309
  def render_bookmarks_control?
    false
  end

  def render_in_tenant?(field_config, _doc)
    return true if Site.account&.hidden_index_fields.blank?

    field_name_components = field_config.key.split('_')
    field_name_components.pop # remove solr suffix
    human_field_name = field_name_components.join('_')

    Site.account
        .hidden_index_fields
        .split(%r{\s*,\s*})
        .exclude?(human_field_name)
  end

  protected

  def cache_control
    expires_in 1.hour, public: true unless Rails.env.test?
  end
end
# rubocop:enable Metrics/ClassLength, Metrics/BlockLength
