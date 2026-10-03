# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Hyrax.publisher subscriptions' do
  # prepare! re-runs every to_prepare block, which replaces the derivative
  # services after_initialize set at boot (samvera/hyku#3359) and appends to
  # I18n.load_path again.
  around do |example|
    derivative_services = Hyrax::DerivativeService.services.dup
    i18n_load_path = I18n.load_path.dup
    example.run
  ensure
    Hyrax::DerivativeService.services = derivative_services
    I18n.load_path = i18n_load_path
  end

  it 'subscribes each listener to an event once after code reloads' do
    3.times { Rails.application.reloader.prepare! }

    duplicates = {}
    Hyrax.publisher.__bus__.listeners.each_pair do |event, subscriptions|
      counts = subscriptions.filter_map { |callable, _filter| callable.receiver.class.name if callable.is_a?(Method) }.tally
      repeated = counts.select { |_name, count| count > 1 }
      duplicates[event] = repeated if repeated.any?
    end

    expect(duplicates).to be_empty
  end
end
