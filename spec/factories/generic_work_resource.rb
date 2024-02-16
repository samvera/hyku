# frozen_string_literal: true

FactoryBot.define do
  factory :generic_work_resource, parent: :hyrax_work, class: 'GenericWorkResource'

  before(:create) do |_work, _e|
    Hyrax::Group.find_or_create_by!(name: ::Ability.admin_group_name)
  end
end
