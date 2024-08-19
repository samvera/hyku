# frozen_string_literal: true

FactoryBot.define do
  factory :hyku_work, parent: :hyrax_work do
    identifier do
      %w[
        ISBN:978-83-7659-303-6 978-3-540-49698-4 9790879392788
        doi:10.1038/nphys1170 3-921099-34-X 3-540-49698-x 0-19-852663-6
      ]
    end
  end

  factory :generic_work_resource, parent: :hyku_work, class: 'GenericWorkResource' do
  end

  factory :image_resource, parent: :hyku_work, class: 'ImageResource' do
  end

  factory :etd_resource, parent: :hyku_work, class: 'EtdResource' do
  end

  factory :oer_resource, parent: :hyku_work, class: 'OerResource' do
  end
end
