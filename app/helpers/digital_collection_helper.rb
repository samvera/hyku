# frozen_string_literal: true

# Helpers for the digital collection theme's home and show pages.
module DigitalCollectionHelper
  def dc_home
    theme_home(DigitalCollection::HomepagePresenter)
  end

  def dc_section_head(title, id:, eyebrow: nil, action: nil, &block)
    tag.div(class: 'dc-section-head') do
      safe_join([
        (tag.p(eyebrow, class: 'dc-section-eyebrow') if eyebrow),
        tag.h2(title, class: 'dc-section-title', id:),
        (capture(&block) if block),
        action
      ].compact)
    end
  end

  def dc_badge(text, kind: nil, class_name: 'dc-badge')
    tag.span(text, class: token_list(class_name, "dc-badge-#{kind}" => kind))
  end
end
