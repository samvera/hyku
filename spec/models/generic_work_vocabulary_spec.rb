# frozen_string_literal: true

RSpec.describe 'GenericWork human-readable vocabulary' do
  # "Generic Work" is model vocabulary leaking into prospect-visible chrome:
  # the type badge on every show page, the deposit type picker, and search
  # facets. Evaluators read it as developer-facing. The human label is "Work".
  it 'labels the ActiveFedora model Work' do
    expect(GenericWork.human_readable_type).to eq('Work')
  end

  it 'labels the Valkyrie resource Work' do
    expect(GenericWorkResource.human_readable_type).to eq('Work')
  end

  it 'labels the deposit type picker Work' do
    expect(I18n.t('hyrax.select_type.generic_work.name')).to eq('Work')
  end
end
