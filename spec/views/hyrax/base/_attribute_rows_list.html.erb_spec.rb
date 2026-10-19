# frozen_string_literal: true

RSpec.describe 'hyrax/base/_attribute_rows_list.html.erb' do
  let(:ability) { double(admin?: false, can?: false) }
  let(:doc) { Nokogiri::HTML(rendered) }
  let(:rendered_fields) { doc.css('li.attribute').map { |li| li['class'][/attribute-(\w+)/, 1] } }

  context 'with a generic work' do
    let(:attributes) do
      {
        id: 'work-1',
        has_model_ssim: ['GenericWorkResource'],
        creator_tesim: ['Lovelace, Ada'],
        subject_tesim: ['Mathematics'],
        keyword_tesim: ['engines'],
        participants_json_ss: [{ name: 'Babbage, Charles', role: 'Editor' }].to_json
      }
    end
    let(:solr_document) { SolrDocument.new(attributes) }
    let(:presenter) { Hyrax::GenericWorkPresenter.new(solr_document, ability) }

    context 'when the work uses the YAML schema' do
      context 'and flexible is off' do
        before { render 'hyrax/base/attribute_rows_list', presenter:, field_order: %i[subject creator participants] }

        it 'renders only the fields in field_order, in that order' do
          expect(rendered_fields).to eq(%w[subject creator participants])
        end

        it 'renders compound fields listed in field_order' do
          expect(doc.at_css('li.attribute-participants').text).to include('Babbage, Charles').and include('Editor')
        end
      end

      context 'and a listed compound has no entries' do
        before do
          allow(Hyrax.logger).to receive(:warn)
          render 'hyrax/base/attribute_rows_list', presenter:, field_order: %i[creator identifiers]
        end

        it 'skips the empty compound without logging a missing-method warning' do
          expect(rendered_fields).to eq(%w[creator])
          expect(Hyrax.logger).not_to have_received(:warn).with(/identifiers/)
        end
      end

      context 'and flexible is on but its class is not flexible' do
        before do
          allow(Hyrax.config).to receive(:flexible?).and_return(true)
          render 'hyrax/base/attribute_rows_list', presenter:, field_order: %i[subject creator participants]
        end

        it 'renders only the fields in field_order, in that order' do
          expect(rendered_fields).to eq(%w[subject creator participants])
        end
      end
    end

    context 'when the work was saved under the m3 profile' do
      let(:attributes) { super().merge(schema_version_ssi: '1') }

      before do
        allow(Hyrax::FlexibleSchema).to receive(:current_version).and_return('properties' => {})
        allow(Hyrax.config).to receive(:flexible?).and_return(flexible)
        allow(view).to receive(:view_options_for).and_return(
          keyword: { 'html_dl' => true }.with_indifferent_access,
          creator: { 'html_dl' => true }.with_indifferent_access
        )
        render 'hyrax/base/attribute_rows_list', presenter:, field_order: %i[subject creator]
      end

      context 'and flexible is on' do
        let(:flexible) { true }

        it 'renders the profile fields in profile order, ignoring field_order' do
          expect(rendered_fields).to eq(%w[keyword creator])
        end
      end

      context 'and flexible has since been turned off' do
        let(:flexible) { false }

        it 'renders the profile fields in profile order, ignoring field_order' do
          expect(rendered_fields).to eq(%w[keyword creator])
        end
      end
    end
  end

  context 'with an ETD admin note' do
    let(:solr_document) do
      SolrDocument.new(id: 'etd-1', has_model_ssim: ['EtdResource'], admin_note_tesim: ['Embargo pending review'])
    end
    let(:presenter) { Hyrax::EtdPresenter.new(solr_document, ability) }

    before do
      allow(presenter).to receive(:editor?).and_return(editor)
      render 'hyrax/base/attribute_rows_list', presenter:, field_order: %i[admin_note]
    end

    context 'when the viewer is an editor who is not an admin' do
      let(:editor) { true }

      it 'shows the admin note' do
        expect(rendered).to include('Embargo pending review')
      end
    end

    context 'when the viewer is not an editor' do
      let(:editor) { false }

      it 'hides the admin note' do
        expect(rendered).not_to include('Embargo pending review')
      end
    end
  end
end
