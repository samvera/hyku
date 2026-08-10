# frozen_string_literal: true

RSpec.describe 'GenericWork human-readable vocabulary' do
  # "Generic Work" is model vocabulary leaking into prospect-visible chrome:
  # the type badge on every show page, the deposit type picker, and search
  # facets. Evaluators read it as developer-facing. The human label is "Work".
  it 'labels the ActiveFedora model Work' do
    I18n.with_locale(:en) do
      expect(GenericWork.human_readable_type).to eq('Work')
    end
  end

  it 'labels the Valkyrie resource Work' do
    I18n.with_locale(:en) do
      expect(GenericWorkResource.human_readable_type).to eq('Work')
    end
  end

  it 'labels the deposit type picker Work' do
    I18n.with_locale(:en) do
      expect(I18n.t('hyrax.select_type.generic_work.name')).to eq('Work')
    end
  end

  # The badge resolves through activefedora.models for ActiveFedora works and
  # hyrax.models for Valkyrie works (activerecord.models as its fallback); if
  # any locale updates one path but not the others, the label a visitor sees
  # depends on which model stack minted the work.
  it 'agrees across both model stacks in every supported locale' do
    %i[en de es fr it pt-BR zh].each do |locale|
      I18n.with_locale(locale) do
        labels = %w[activefedora.models.generic_work
                    activerecord.models.generic_work
                    hyrax.models.generic_work].map { |key| I18n.t(key) }
        expect(labels.uniq.size).to eq(1), "#{locale}: #{labels.inspect}"
      end
    end
  end
end
