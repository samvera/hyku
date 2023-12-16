# frozen_string_literal: true

module ApplicationHelper
  include ::HyraxHelper
  include Hyrax::OverrideHelperBehavior
  include GroupNavigationHelper
  include SharedSearchHelper
  include HykuKnapsack::ApplicationHelper

  def hint_for(term:, record_class: nil)
    hint = locale_for(type: 'hints', term:, record_class:)

    return hint unless missing_translation(hint)
  end

  def locale_for(type:, term:, record_class:)
    @term              = term.to_s
    @record_class      = record_class.to_s.downcase
    work_or_collection = @record_class == 'collection' ? 'collection' : 'defaults'
    default_locale     = t("simple_form.#{type}.#{work_or_collection}.#{@term}")
    locale             = t("hyrax.#{@record_class}.#{type}.#{@term}")

    return default_locale if missing_translation(locale)

    locale
  end

  def missing_translation(value, _options = {})
    value.include?('translation missing')
  end
end
