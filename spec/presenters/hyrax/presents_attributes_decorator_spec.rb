# frozen_string_literal: true

RSpec.describe Hyrax::PresentsAttributesDecorator do
  let(:presenter) { Hyku::WorkShowPresenter.new(solr_document, nil) }
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:attributes) do
    { id: 'labels-1',
      has_model_ssim: ['GenericWork'],
      title_tesim: ['A Title'],
      license_tesim: ['http://creativecommons.org/licenses/by/3.0/us/'],
      license_label_tesim: ['Attribution 3.0 United States'] }
  end

  describe '#attribute_to_html' do
    it 'renders the term label rather than the stored id' do
      expect(presenter.attribute_to_html(:license)).to include 'Attribution 3.0 United States'
    end

    it 'links the label to the stored id' do
      expect(presenter.attribute_to_html(:license))
        .to include 'href="http://creativecommons.org/licenses/by/3.0/us/"'
    end

    context 'when the work was indexed before the label fields existed' do
      let(:attributes) do
        { id: 'labels-2',
          has_model_ssim: ['GenericWork'],
          license_tesim: ['http://creativecommons.org/licenses/by/3.0/us/'] }
      end

      it 'falls back to the stored id' do
        expect(presenter.attribute_to_html(:license))
          .to include 'http://creativecommons.org/licenses/by/3.0/us/'
      end
    end

    context 'when the tesim label field is present but empty' do
      let(:attributes) do
        { id: 'labels-3',
          has_model_ssim: ['GenericWork'],
          license_tesim: ['http://creativecommons.org/licenses/by/3.0/us/'],
          license_label_tesim: [],
          license_label_sim: ['Attribution 3.0 United States'] }
      end

      it 'falls back to the sim label rather than treating empty as an answer' do
        expect(presenter.attribute_to_html(:license)).to include 'Attribution 3.0 United States'
      end
    end

    context 'for a property with no label field' do
      it 'renders the stored value' do
        expect(presenter.attribute_to_html(:title)).to include 'A Title'
      end
    end

    # license carries `render_as: external_link` in Hyku's profile, and a profile is
    # per-tenant data — so the label has to win without anyone editing one.
    describe 'whichever renderer the profile selects' do
      [nil, :external_link, :license, :faceted].each do |render_as|
        it "shows the label with render_as: #{render_as.inspect}" do
          options = render_as ? { render_as: } : {}

          expect(presenter.attribute_to_html(:license, options))
            .to include 'Attribution 3.0 United States'
        end
      end
    end
  end
end
