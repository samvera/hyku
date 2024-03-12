# frozen_string_literal: true

module ApplicationHelper
  # Yep, we're ignoring the advice; because the translations are safe as is the markdown converter.
  # rubocop:disable Rails/OutputSafety
  include ::HyraxHelper
  include SharedSearchHelper
  include Bulkrax::ApplicationHelper
  include HykuKnapsack::ApplicationHelper

  def group_navigation_presenter
    @group_navigation_presenter ||= Hyku::Admin::Group::NavigationPresenter.new(params:)
  end

  def collection_thumbnail(_document, _image_options = {}, _url_options = {})
    return super if Site.instance.default_collection_image.blank?

    image_tag(Site.instance.default_collection_image&.url)
  end

  def label_for(term:, record_class: nil)
    locale_for(type: 'labels', term:, record_class:)
  end

  def hint_for(term:, record_class: nil)
    hint = locale_for(type: 'hints', term:, record_class:)

    return hint unless missing_translation(hint)
  end

  def locale_for(type:, term:, record_class:)
    term              = term.to_s
    record_class      = record_class.to_s.downcase
    work_or_collection = record_class == 'collection' ? 'collection' : 'defaults'
    locale             = t("hyrax.#{record_class}.#{type}.#{term}")

    if missing_translation(locale)
      (t("simple_form.#{type}.#{work_or_collection}.#{term}") || term.titleize) .html_safe
    else
      locale.html_safe
    end
  end

  def missing_translation(value, _options = {})
    return true if value == false
    return true if value.try(:false?)
    false
  end

  def markdown(text)
    options = %i[
      hard_wrap autolink no_intra_emphasis tables fenced_code_blocks
      disable_indented_code_blocks strikethrough lax_spacing space_after_headers
      quote footnotes highlight underline
    ]
    text ||= ""
    Markdown.new(text, *options).to_html.html_safe
  end

  def truncate_and_iconify_auto_link(*args)
    iconify_auto_link(*args).truncate(230, separator: ' ')
  end
  # rubocop:enable Rails/OutputSafety
end
