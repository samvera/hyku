# frozen_string_literal: true

RSpec.configure do |config|
  config.after { I18n.locale = I18n.default_locale }
end
