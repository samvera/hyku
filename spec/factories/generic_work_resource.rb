# frozen_string_literal: true

FactoryBot.define do
  factory :generic_work_resource, parent: :hyrax_work, class: 'GenericWorkResource' do
    identifier do
      %w[
        ISBN:978-83-7659-303-6 978-3-540-49698-4 9790879392788
        doi:10.1038/nphys1170 3-921099-34-X 3-540-49698-x 0-19-852663-6
      ]
    end
  end
end
