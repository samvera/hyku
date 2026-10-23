# frozen_string_literal: true

RSpec.describe Hyrax::ContextualPath do
  let(:file_set) { instance_double(Hyrax::FileSetPresenter, id: 'fs1', model_name: Hyrax::FileSet.model_name) }
  let(:parent) { instance_double(Hyrax::WorkShowPresenter, id: 'work1') }

  it 'links a member under its parent without a locale in the default language' do
    expect(described_class.new(file_set, parent).show).to eq('/concern/parent/work1/file_sets/fs1')
  end

  it 'keeps a chosen language on the link' do
    I18n.with_locale(:es) do
      expect(described_class.new(file_set, parent).show).to eq('/concern/parent/work1/file_sets/fs1?locale=es')
    end
  end
end
