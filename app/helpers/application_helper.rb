# frozen_string_literal: true

module ApplicationHelper
  include ::HyraxHelper
  include Hyrax::OverrideHelperBehavior
  include GroupNavigationHelper

  def label_for(term:, record_class: nil)
    locale_for(type: 'labels', term: term, record_class: record_class)
  end

  def hint_for(term:, record_class: nil)
    hint = locale_for(type: 'hints', term: term, record_class: record_class)

    return hint unless hint.include?('translation missing')
  end

  def locale_for(type:, term:, record_class:)
    @term              = term.to_s
    @record_class      = record_class.to_s.downcase
    work_or_collection = @record_class == 'collection' ? 'collection' : 'defaults'
    default_locale     = t("simple_form.#{type}.#{work_or_collection}.#{@term}").html_safe
    locale             = t("hyrax.#{@record_class}.#{type}.#{@term}").html_safe

    return default_locale if locale.include?('translation missing')

    locale
  end
end
