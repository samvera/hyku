# frozen_string_literal: true

RSpec.describe Hyrax::AttributesHelper, type: :helper do
  it 'translates a show page label kept under its Solr field name' do
    label = I18n.with_locale(:es) { helper.conform_options(:creator, {}.with_indifferent_access)[:label] }

    expect(label).to eq('Creador')
  end

  it 'keeps a label the metadata profile gives for the current language' do
    options = { display_label: { es: 'Autoría', default: 'Creator' } }.with_indifferent_access

    expect(I18n.with_locale(:es) { helper.conform_options(:creator, options)[:label] }).to eq('Autoría')
  end

  it 'translates a profile label given as a translation key for the current language' do
    options = { display_label: { es: 'blacklight.search.fields.show.creator_tesim', default: 'Creator' } }.with_indifferent_access

    expect(I18n.with_locale(:es) { helper.conform_options(:creator, options)[:label] }).to eq('Creador')
  end

  it 'still humanizes a field with no translation anywhere' do
    expect(helper.conform_options(:made_up_field, {}.with_indifferent_access)[:label]).to eq('Made up field')
  end
end
