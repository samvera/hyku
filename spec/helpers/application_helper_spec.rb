# frozen_string_literal: true

RSpec.describe ApplicationHelper, type: :helper do
  describe '#thumbnail_alt_text_for' do
    let(:document) { SolrDocument.new('has_model_ssim' => ['GenericWork'], 'thumbnail_alt_text_tesim' => thumbnail_alt_text, 'title_tesim' => ['My Work']) }

    context 'when the document has thumbnail_alt_text (real thumbnail)' do
      let(:thumbnail_alt_text) { ['Custom alt text'] }

      it 'returns alt_text_for_view from the document' do
        expect(helper.thumbnail_alt_text_for(document)).to eq(document.alt_text_for_view)
      end

      it 'does not check the content block' do
        expect(helper).not_to receive(:block_for)
        helper.thumbnail_alt_text_for(document)
      end
    end

    context 'when the document has no thumbnail_alt_text (default image showing)' do
      let(:thumbnail_alt_text) { [] }

      context 'when a content block is configured' do
        before { allow(helper).to receive(:block_for).with(name: 'default_work_image_text').and_return('Site default alt') }

        it 'returns the content block value' do
          expect(helper.thumbnail_alt_text_for(document)).to eq('Site default alt')
        end
      end

      context 'when no content block is configured' do
        before { allow(helper).to receive(:block_for).with(name: 'default_work_image_text').and_return(nil) }

        it 'falls back to the default sr thumbnail translation' do
          expect(helper.thumbnail_alt_text_for(document)).to eq(t('hyrax.sr.thumbnail'))
        end
      end

      context 'with a collection block_name' do
        before { allow(helper).to receive(:block_for).with(name: 'default_collection_image_text').and_return('Collection default') }

        it 'uses the provided block_name' do
          expect(helper.thumbnail_alt_text_for(document, block_name: 'default_collection_image_text')).to eq('Collection default')
        end
      end
    end
  end

  describe "#markdown" do
    let(:header) { '# header' }
    let(:bold) { '*bold*' }

    context 'when treat_some_user_inputs_as_markdown is true' do
      it 'renders markdown into html' do
        allow(Flipflop).to receive(:treat_some_user_inputs_as_markdown?).and_return(true)

        expect(helper.markdown(header)).to eq("<h1>header</h1>\n")
        expect(helper.markdown(bold)).to eq("<p><em>bold</em></p>\n")
      end
    end

    context 'when treat_some_user_inputs_as_markdown is false' do
      it 'does not render markdown into html' do
        allow(Flipflop).to receive(:treat_some_user_inputs_as_markdown?).and_return(false)

        expect(helper.markdown(header)).to eq('# header')
        expect(helper.markdown(bold)).to eq('*bold*')
      end
    end
  end

  describe '#local_for' do
    context 'when term is missing' do
      it 'returns nil' do
        expect(helper.locale_for(type: 'labels', record_class: "account", term: :very_much_missing)).to be_nil
      end
    end

    context 'when the term exists only in the simple_form scope' do
      it 'falls back to the simple_form translation' do
        allow(I18n).to receive(:t).and_call_original
        allow(I18n).to receive(:t).with('hyrax.account.hints.title', default: nil).and_return(nil)
        allow(I18n).to receive(:t).with('simple_form.hints.defaults.title', default: nil).and_return('A hint')
        expect(helper.locale_for(type: 'hints', record_class: 'account', term: :title)).to eq('A hint')
      end
    end
  end

  describe 'missing view translations' do
    # A helper named missing_translation shadows Rails' private TranslationHelper
    # hook, and its return value gets rendered into the page.
    it 'does not render a literal false for a missing key' do
      expect(helper.t('hyku.specs.definitely_missing_key')).not_to eq(false)
    end
  end

  describe '#work_type_facet_label' do
    it 'returns the human model name from the locales' do
      # Hyrax overrides model_name on resource classes, so the i18n key is
      # :generic_work, not :generic_work_resource - derive it instead of
      # hardcoding it.
      key = "activerecord.models.#{GenericWorkResource.model_name.i18n_key}"
      allow(I18n).to receive(:t).and_call_original
      allow(I18n).to receive(:t).with(key, count: 1, default: 'Generic Work Resource')
                                .and_return('Generic Work')
      expect(helper.work_type_facet_label('GenericWorkResource')).to eq('Generic Work')
    end

    it 'unwraps a Blacklight facet item' do
      item = double(value: 'GenericWorkResource')
      expect(helper.work_type_facet_label(item)).to be_a(String)
    end

    it 'titleizes values that are not model classes (stale index data)' do
      expect(helper.work_type_facet_label('NoSuchModel')).to eq('No Such Model')
    end
  end

  describe '#options_including_current' do
    let(:options) { [['Article', 'Article']] }
    let(:service) do
      Class.new do
        # Mirrors Hyrax::AuthorityService, which appends only a value it no longer
        # offers and returns the options alongside the html options.
        def self.include_current_value(value, _index, render_options, html_options)
          return [render_options, html_options] if render_options.flatten.include?(value)

          [render_options + [[value, value]], html_options]
        end
      end
    end

    it 'offers the given options when nothing is stored' do
      expect(helper.options_including_current(options, service, [])).to eq [['Article', 'Article']]
    end

    it 'keeps a retired term the record still stores' do
      expect(helper.options_including_current(options, service, ['Retired']))
        .to eq [['Article', 'Article'], %w[Retired Retired]]
    end

    it 'ignores a blank stored value' do
      expect(helper.options_including_current(options, service, ['', nil])).to eq [['Article', 'Article']]
    end

    it 'does not repeat a stored term that is still offered' do
      expect(helper.options_including_current(options, service, ['Article'])).to eq [['Article', 'Article']]
    end

    # A single-valued field hands over a bare string rather than an array.
    it 'accepts a value that is not an array' do
      expect(helper.options_including_current(options, service, 'Retired'))
        .to eq [['Article', 'Article'], %w[Retired Retired]]
    end

    context 'when the service cannot re-add a current value' do
      let(:service) { Class.new }

      it 'returns the given options' do
        expect(helper.options_including_current(options, service, ['Retired'])).to eq [['Article', 'Article']]
      end
    end
  end
end
