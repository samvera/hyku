# frozen_string_literal: true

# Builds the digital collection theme's search result rows and card meta lines.
module DigitalCollectionResultHelper
  def dc_card_meta(document, collection_label: false)
    parts = if document.collection?
              [(t('digital_collection.search.results.collection') if collection_label), dc_works_count_label(document)]
            else
              [(Array(document['creator_tesim']).first if dc_result_field_shown?(document, 'creator_tesim')), dc_result_date(document)]
            end
    parts.compact_blank.join(' · ')
  end

  def dc_result_fields(document)
    return dc_profile_result_fields(document) if Hyrax.config.flexible?

    fields = document.collection? ? dc_collection_result_values(document) : dc_work_result_values(document)
    fields.filter_map do |key, value|
      [key, dc_result_row(t("digital_collection.search.results.fields.#{key}"), value)] if value.present?
    end
  end

  private

  def dc_profile_result_fields(document)
    rows = document_presenter(document).fields_to_render.filter_map do |field_name, _config, presenter|
      next if field_name.to_s.start_with?('title_')

      value = presenter.render
      [dc_result_field_key(field_name), dc_result_row(index_field_label(document, field_name), markdown(value))] if value.present?
    end
    extra = document.collection? ? [:works, dc_works_count_label(document)] : [:part_of, dc_part_of_links(document)]
    extra.last.present? ? rows << [extra.first, dc_result_row(t("digital_collection.search.results.fields.#{extra.first}"), extra.last)] : rows
  end

  def dc_result_field_shown?(document, field_name)
    return true unless Hyrax.config.flexible?

    @dc_result_fields_shown ||= {}
    shown = @dc_result_fields_shown[document.id] ||= document_presenter(document).fields_to_render.map { |name, _config, _presenter| name.to_s }
    shown.include?(field_name)
  end

  def dc_result_field_key(field_name)
    field_name.to_s.sub(/_(tesim|ssim|sim|ssi|tesi|dtsi|isim|itsi)\z/, '').to_sym
  end

  def dc_result_row(label, value)
    safe_join([tag.dt(label), tag.dd(value)])
  end

  def dc_work_result_values(document)
    { creator: Array(document['creator_tesim']).join('; '),
      date: dc_result_date(document),
      part_of: dc_part_of_links(document),
      resource_type: Array(document['resource_type_tesim']).join(', '),
      description: theme_blurb(Array(document['description_tesim']).first, length: 300) }
  end

  def dc_collection_result_values(document)
    { description: theme_blurb(Array(document['description_tesim']).first, length: 300),
      works: dc_works_count_label(document) }
  end

  def dc_works_count_label(document)
    t('digital_collection.homepage.browse.works_count', count: Hyrax::CollectionPresenter.new(document, current_ability).total_viewable_works)
  end

  def dc_result_date(document)
    %w[date_created_tesim date_issued_tesim].each do |field_name|
      value = Array(document[field_name]).first
      return value if value.present? && dc_result_field_shown?(document, field_name)
    end
    nil
  end

  def dc_part_of_links(document)
    ids = Array(document['member_of_collection_ids_ssim'])
    links = Array(document['member_of_collections_ssim']).each_with_index.map do |name, index|
      ids[index] ? link_to(name, hyrax.collection_path(ids[index])) : name
    end
    safe_join(links, ', ')
  end
end
