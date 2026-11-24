# frozen_string_literal: true

RSpec.describe Hyrax::Forms::FileSetForm do
  it 'saves the bulkrax_identifier, so Bulkrax can find the file sets it imports' do
    form = described_class.new(resource: Hyrax::FileSet.new)
    form.validate(bulkrax_identifier: 'fs-1')
    form.sync

    expect(form.model.bulkrax_identifier).to eq 'fs-1'
  end
end
