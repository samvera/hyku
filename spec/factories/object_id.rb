# NOTE(bkiahstroud): Override file from Hyrax 2.5.1
# Defines a new sequence
FactoryBot.define do
  sequence :object_id do |n|
    "object_id_#{n}"
  end
end
