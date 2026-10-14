# frozen_string_literal: true

module ApplicationHelper
  # Yep, we're ignoring the advice; because the translations are safe as is the markdown converter.
  # rubocop:disable Rails/OutputSafety
  include ::HyraxHelper
  include SharedSearchHelper
  include Bulkrax::ApplicationHelper
  include HykuKnapsack::ApplicationHelper
  include Hyrax::FormHelperBehavior
  include Hyrax::AttachedFilesHelperBehavior
  include Hyku::HomepageHelper

  def group_navigation_presenter
    @group_navigation_presenter ||= Hyku::Admin::Group::NavigationPresenter.new(params:)
  end

  # Facet label for a has_model_ssim value (the "Work Type" facet): the human
  # model name from the app's locales (activerecord.models.*), so a value like
  # "GenericWorkResource" can render as whatever the installation calls it.
  # Blacklight passes a facet item (not a bare string), so unwrap it first.
  # The locale entries may be pluralized (one:/other:), which model_name.human
  # does not resolve, so look them up with an explicit count. Falls back to
  # titleizing unknown values so the facet never breaks on stale index data.
  def work_type_facet_label(value)
    name = (value.respond_to?(:value) ? value.value : value).to_s
    klass = name.safe_constantize
    return name.titleize unless klass.respond_to?(:model_name)

    I18n.t("activerecord.models.#{klass.model_name.i18n_key}", count: 1, default: name.titleize)
  end

  # Facet label for a generic_type_sim value (the "Type" facet). This facet holds
  # a small fixed set of coarse type tokens ("Work", "Collection", "Admin Set") —
  # not class names — so each token maps directly to a locale key under
  # hyku.generic_type, letting an installation rename ANY of them (e.g.
  # "Collection" -> "User Collection") via locale alone. An unmapped token falls
  # back to its own text, so a new/stale value never breaks the facet.
  def generic_type_facet_label(value)
    token = (value.respond_to?(:value) ? value.value : value).to_s
    I18n.t(token.parameterize(separator: '_'), scope: 'hyku.generic_type', default: token)
  end

  # Return collection thumbnail formatted for display:
  #  - use collection's branding thumbnail if it exists
  #  - use site's default collection image if one exists
  #  - fallback to Hyrax's default image
  def collection_thumbnail(document, _image_options = {}, url_options = {})
    view_class = url_options[:class]
    alt = thumbnail_alt_text_for(document, block_name: 'default_collection_image_text')

    # The correct thumbnail SHOULD be indexed on the object
    return image_tag(document['thumbnail_path_ss'], class: view_class, alt:) if document['thumbnail_path_ss'].present?

    # If nothing is indexed, we just fall back to site default
    return image_tag(Site.instance.default_collection_image&.url, alt:, class: view_class) if Site.instance.default_collection_image.present?

    # fall back to Hyrax default if no site default
    tag.span("", class: [Hyrax::ModelIcon.css_class_for(::Collection), view_class], alt:)
  end

  # OVERRIDE Hyrax to add content-block lookup when no custom thumbnail alt text is indexed.
  # @param document [SolrDocument]
  # @param block_name [String] content block name for the default image alt text
  def thumbnail_alt_text_for(document, block_name: 'default_work_image_text')
    return document.alt_text_for_view if document.respond_to?(:thumbnail_alt_text) && document.thumbnail_alt_text.present?

    block_for(name: block_name) || super
  end

  # A term retired after a record stored it is not among the options, so the browser
  # posts the select without it and the term is dropped on save. include_current_value
  # adds those back. Its html_options, which carry the force-select class, are
  # discarded here as upstream's partials do: the option is kept, not distinguished.
  def options_including_current(options, service, values)
    return options unless service.respond_to?(:include_current_value)

    Array.wrap(values).select(&:present?).reduce(options) do |collected, value|
      service.include_current_value(value, nil, collected, { class: [] }).first
    end
  end

  def label_for(term:, record_class: nil)
    locale_for(type: 'labels', term:, record_class:)
  end

  def alttext_for(collection)
    Deprecation.warn(self, "alttext_for is deprecated. Use thumbnail_alt_text_for(document) instead.")
    thumbnail = CollectionBrandingInfo.where(collection_id: collection.id, role: "thumbnail")&.first
    return thumbnail.alt_text if thumbnail
    block_for(name: 'default_collection_image_text') || "#{collection.title_or_label} #{t('hyrax.dashboard.my.sr.thumbnail')}"
  end

  def hint_for(term:, record_class: nil)
    locale_for(type: 'hints', term:, record_class:)
  end

  def color_hint_for(color_name)
    I18n.t("hyrax.admin.appearances.show.forms.#{color_name}.hint", default: nil)
  end

  def locale_for(type:, term:, record_class:)
    term              = term.to_s
    record_class      = record_class.to_s.underscore
    work_or_collection = record_class == Hyrax.config.collection_model.underscore ? 'collection' : 'defaults'
    locale             = I18n.t("hyrax.#{record_class}.#{type}.#{term}", default: nil) ||
                         I18n.t("simple_form.#{type}.#{work_or_collection}.#{term}", default: nil)

    locale&.html_safe
  end

  def markdown(text)
    return text unless Flipflop.treat_some_user_inputs_as_markdown?

    # Consider extracting these options to a Hyku::Application
    # configuration/class attribute.
    options = %i[
      hard_wrap autolink no_intra_emphasis tables fenced_code_blocks
      disable_indented_code_blocks strikethrough lax_spacing space_after_headers
      quote footnotes highlight underline
    ]
    text ||= ""
    Markdown.new(text, *options).to_html.html_safe
  end
  # rubocop:enable Rails/OutputSafety

  def truncate_and_iconify_auto_link(field, show_link = true)
    if field.is_a? Hash
      options = field[:config].separator_options || {}
      text = field[:value].to_sentence(options)
    else
      text = field
    end
    # this block is only executed when a link is inserted;
    # if we pass text containing no links, it just returns text.
    auto_link(html_escape(text)) do |value|
      "<span class='fa fa-external-link'></span>#{('&nbsp;' + value) if show_link}"
    end.truncate(230, separator: ' ')
  end
end
