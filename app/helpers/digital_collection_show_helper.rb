# frozen_string_literal: true

# Helpers for the digital collection theme's collection, work and file set pages.
module DigitalCollectionShowHelper
  def dc_inline_markdown(text)
    html = markdown(text.to_s).to_s.strip
    sanitize(html.delete_prefix('<p>').delete_suffix('</p>'))
  end

  def dc_collection_type_label(collection_type)
    key = if collection_type.user_collection?
            'hyrax.collection_type.default_title'
          elsif collection_type.admin_set?
            'hyrax.collection_type.admin_set_title'
          end
    key && collection_type.title == I18n.t(key, locale: :en) ? t(key) : collection_type.title
  end

  def dc_collection_meta(presenter)
    updated = dc_date(presenter.modified_date)
    parts = [
      (t('digital_collection.collection.created_by', creator: presenter.creator.first) if presenter.creator.present?),
      tag.strong(t('digital_collection.collection.items', count: presenter.total_viewable_items)),
      (t('digital_collection.collection.updated', date: l(updated, format: t('digital_collection.collection.date_format'))) if updated)
    ]
    safe_join(parts.compact, ' · ')
  end

  DC_COLLECTION_SHOWN_ELSEWHERE = %i[title date_modified description total_items].freeze

  def dc_collection_metadata_rows(presenter)
    return dc_collection_term_rows(presenter) unless Hyrax.config.flexible?

    dc_collection_view_definitions(presenter).filter_map do |field, options|
      next if DC_COLLECTION_SHOWN_ELSEWHERE.include?(field.to_sym) || compound_card_field?(presenter, field)

      view_options = conform_options(field, options.deep_dup.with_indifferent_access)
      next unless field_visible?(view_options, presenter)

      dc_collection_metadata_row(presenter, conform_field(field, options), view_options)
    end
  end

  def dc_breadcrumb_trail(presenter)
    home = [t('hyrax.controls.home'), hyrax.root_path]
    case presenter
    when Hyrax::CollectionPresenter
      [home, [presenter.to_s, nil], dc_back_to_search_crumb].compact
    when Hyrax::FileSetPresenter
      work = presenter.parent
      [home, dc_collection_crumb(work), ([work.to_s, main_app.polymorphic_path(work)] if work)].compact
    else
      [home, dc_collection_crumb(presenter), [presenter.to_s, nil], dc_back_to_search_crumb].compact
    end
  end

  private

  def dc_collection_view_definitions(presenter)
    dc_profile_view_definitions(presenter.solr_document)
  end

  def dc_collection_metadata_row(presenter, field, view_options)
    if presenter.respond_to?(:compound_term?) && presenter.compound_term?(field)
      value = collection_metadata_value(presenter, field)
      safe_join([tag.dt(view_options[:label]), tag.dd(value)]) if value.present?
    elsif presenter.solr_document.respond_to?(field)
      presenter.attribute_to_html(field, view_options).presence
    end
  end

  def dc_collection_term_rows(presenter)
    (presenter.terms_with_values - DC_COLLECTION_SHOWN_ELSEWHERE).map do |field|
      safe_join([tag.dt(collection_metadata_label(presenter, field)), tag.dd(collection_metadata_value(presenter, field))])
    end
  end

  def dc_date(value)
    Date.parse(value.to_s) if value.present?
  rescue Date::Error
    nil
  end

  def dc_collection_crumb(work)
    collection = work.try(:member_of_collection_presenters)&.find { |parent| parent.is_a?(Hyrax::CollectionPresenter) }
    [collection.to_s, hyrax.collection_path(collection.id)] if collection
  end

  def dc_back_to_search_crumb
    referer = URI.parse(request.referer.to_s)
    return unless referer.host == request.host && referer.path.start_with?(URI.parse(main_app.search_catalog_path).path)

    [t('hyrax.bread_crumb.search_results'), request.referer]
  rescue URI::InvalidURIError
    nil
  end
end
