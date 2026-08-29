# frozen_string_literal: true

module PracticeResearchHomeHelper
  NAMED_CONTRIBUTORS = 2
  CARD_BLURB_LENGTH = 150

  def pr_home
    theme_home(PracticeResearch::HomepagePresenter)
  end

  def pr_featured_researcher?
    @featured_researcher&.value.present?
  end

  def pr_card_blurb(presenter, length: CARD_BLURB_LENGTH)
    text = Array(presenter.try(:description)).first
    return if text.blank?

    truncate(pr_plain_text(text), length:, separator: ' ')
  end

  def pr_plain_text(html)
    Nokogiri::HTML.fragment(html.to_s.gsub(%r{</?[a-zA-Z][^>]*>}, ' ')).text.squish
  end

  def pr_thumbnail?(presenter)
    path = presenter.thumbnail_path

    path.is_a?(String) && path.present? && path != Hyrax::ThumbnailPathService.default_image
  end

  def pr_contributor_summary(document)
    names = pr_contributor_names(document)
    return if names.empty?

    rest = names.size - NAMED_CONTRIBUTORS
    return names.to_sentence if rest < 1

    t('practice_research.homepage.featured.contributors_and_others',
      names: names.first(NAMED_CONTRIBUTORS).join('; '), count: rest)
  end

  private

  def pr_contributor_names(document)
    rows = begin
             JSON.parse(Array(document['participants_json_ss']).first.to_s)
           rescue JSON::ParserError
             []
           end
    names = Array(rows).filter_map { |row| row['name'] if row.is_a?(Hash) }.compact_blank

    names.presence || Array(document['creator_tesim']).compact_blank
  end
end
