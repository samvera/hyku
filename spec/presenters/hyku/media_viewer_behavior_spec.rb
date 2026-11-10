# frozen_string_literal: true

RSpec.describe Hyku::MediaViewerBehavior do
  subject(:presenter) { Hyku::WorkShowPresenter.new(solr_document, ability, nil) }

  let(:solr_document) { SolrDocument.new({ 'media_viewer_ssi' => selected_viewer }.compact) }
  let(:selected_viewer) { nil }
  let(:ability) { instance_double(Ability) }
  let!(:test_strategy) { Flipflop::FeatureSet.current.test! }
  let(:feature_default) { Flipflop::FeatureSet.current.feature(:per_work_media_viewer).default }

  before { test_strategy.switch!(:per_work_media_viewer, true) }
  after { test_strategy.switch!(:per_work_media_viewer, feature_default) }

  context 'when the feature is disabled' do
    let(:selected_viewer) { 'clover' }

    before { test_strategy.switch!(:per_work_media_viewer, false) }

    it 'ignores the stored choice and renders the tenant default' do
      expect(presenter.iiif_viewer).to eq(:universal_viewer)
    end

    it 'leaves #iiif_viewer? to the tenant-level checks' do
      allow(presenter).to receive_messages(representative_id: '1',
                                           representative_presenter: double('file_set_presenter'))
      allow(Hyrax.config).to receive(:iiif_image_server?).and_return(false)

      expect(presenter.iiif_viewer?).to be_falsey
    end

    it 'leaves #show_pdf_viewer? to the tenant default_pdf_viewer flag' do
      allow(presenter).to receive(:file_set_presenters).and_return([double('fsp', pdf?: true)])
      test_strategy.switch!(:default_pdf_viewer, false)

      expect(presenter.show_pdf_viewer?).to be_falsey
    end
  end

  describe '#iiif_viewer' do
    context 'when clover is chosen' do
      let(:selected_viewer) { 'clover' }

      it { expect(presenter.iiif_viewer).to eq(:clover) }
    end

    context 'when ramp is chosen' do
      let(:selected_viewer) { 'ramp' }

      it { expect(presenter.iiif_viewer).to eq(:ramp) }
    end

    context 'when universal_viewer is chosen' do
      let(:selected_viewer) { 'universal_viewer' }

      it { expect(presenter.iiif_viewer).to eq(:universal_viewer) }
    end

    context 'when unset' do
      it 'falls back to super, the stock :universal_viewer default' do
        expect(presenter.iiif_viewer).to eq(:universal_viewer)
      end
    end

    context 'when pdf_js is chosen' do
      let(:selected_viewer) { 'pdf_js' }

      it 'falls back to super, since pdf_js is not an IIIF viewer' do
        expect(presenter.iiif_viewer).to eq(:universal_viewer)
      end
    end

    context 'when the stored value is not a known viewer' do
      let(:selected_viewer) { 'not_a_viewer' }

      it 'falls back to super rather than naming a partial that does not exist' do
        expect(presenter.iiif_viewer).to eq(:universal_viewer)
      end
    end
  end

  describe '#iiif_viewer?' do
    context 'when pdf_js is chosen' do
      let(:selected_viewer) { 'pdf_js' }

      it 'is false even when super would show a viewer' do
        allow(presenter).to receive_messages(representative_id: '1',
                                             representative_presenter: double('file_set_presenter'),
                                             image_viewable?: true, members_include_viewable_image?: true)
        allow(Hyrax.config).to receive(:iiif_image_server?).and_return(true)

        expect(presenter.iiif_viewer?).to be(false)
      end
    end

    context 'when an IIIF viewer is chosen and the work has a representative' do
      let(:selected_viewer) { 'universal_viewer' }
      let(:image) { double('file_set_presenter', id: 'image', image?: true) }
      let(:pdf) { double('file_set_presenter', id: 'pdf', pdf?: true) }

      before do
        allow(presenter).to receive_messages(representative_id: '1',
                                             representative_presenter: double('file_set_presenter'))
        allow(ability).to receive(:can?).with(:read, anything).and_return(true)
        allow(presenter).to receive(:child_works_viewable?).and_return(false)
        # The explicit choice still skips super's image server check
        allow(Hyrax.config).to receive(:iiif_image_server?).and_return(false)
      end

      it 'is true when only a child work is viewable' do
        allow(presenter).to receive(:file_set_presenters).and_return([])
        allow(presenter).to receive(:child_works_viewable?).and_return(true)

        expect(presenter.iiif_viewer?).to be(true)
      end

      it 'is true when a member is an image, audio or video file' do
        allow(presenter).to receive(:file_set_presenters).and_return([pdf, image])

        expect(presenter.iiif_viewer?).to be(true)
      end

      it 'is false when the only file is a PDF, whose manifest would be empty' do
        allow(presenter).to receive(:file_set_presenters).and_return([pdf])

        expect(presenter.iiif_viewer?).to be(false)
      end

      it 'is false when the user may not read the viewable member' do
        allow(presenter).to receive(:file_set_presenters).and_return([image])
        allow(ability).to receive(:can?).with(:read, 'image').and_return(false)

        expect(presenter.iiif_viewer?).to be(false)
      end

      context 'when IIIF Print splits PDFs into pages' do
        before { allow(IiifPrint::TenantConfig).to receive(:use_iiif_print?).and_return(true) }

        before { allow(presenter).to receive_messages(file_set_presenters: [pdf], iiif_presentable_member_presenters: [pdf]) }

        it 'is true once the PDF is split, so its pages show in the chosen viewer' do
          allow(presenter).to receive(:child_works_viewable?).and_return(true)

          expect(presenter.iiif_viewer?).to be(true)
        end

        it 'is false for a PDF not yet split into pages' do
          expect(presenter.iiif_viewer?).to be(false)
        end
      end
    end

    context 'when an IIIF viewer is chosen but the work has no representative' do
      let(:selected_viewer) { 'clover' }

      it 'is false' do
        expect(presenter.iiif_viewer?).to be_falsey
      end
    end
  end

  describe '#show_pdf_viewer?' do
    let(:pdf) { double('file_set_presenter', pdf?: true) }
    let(:image) { double('file_set_presenter', pdf?: false) }

    context 'when pdf_js is chosen and a PDF file set is present' do
      let(:selected_viewer) { 'pdf_js' }

      it 'is true' do
        allow(presenter).to receive(:file_set_presenters).and_return([image, pdf])

        expect(presenter.show_pdf_viewer?).to be(true)
      end
    end

    context 'when pdf_js is chosen while the tenant-wide default_pdf_viewer flag is off' do
      let(:selected_viewer) { 'pdf_js' }
      let(:default_value) { Flipflop::FeatureSet.current.feature(:default_pdf_viewer).default }

      before { test_strategy.switch!(:default_pdf_viewer, false) }
      after { test_strategy.switch!(:default_pdf_viewer, default_value) }

      it 'still shows the viewer, because the per-work choice overrides the tenant default' do
        allow(presenter).to receive(:file_set_presenters).and_return([pdf])

        expect(presenter.show_pdf_viewer?).to be(true)
      end
    end

    context 'when pdf_js is chosen but no PDF file set is present' do
      let(:selected_viewer) { 'pdf_js' }

      it 'defers to super' do
        allow(presenter).to receive(:file_set_presenters).and_return([image])

        expect(presenter.show_pdf_viewer?).to be_falsey
      end
    end

    context 'when an IIIF viewer is chosen but has nothing to show' do
      let(:selected_viewer) { 'clover' }

      before { allow(presenter).to receive(:iiif_viewer?).and_return(false) }

      it 'falls back to PDF.js for a PDF' do
        allow(presenter).to receive(:file_set_presenters).and_return([pdf])

        expect(presenter.show_pdf_viewer?).to be(true)
      end

      context 'while the tenant-wide default_pdf_viewer flag is off' do
        let(:default_value) { Flipflop::FeatureSet.current.feature(:default_pdf_viewer).default }

        before { test_strategy.switch!(:default_pdf_viewer, false) }
        after { test_strategy.switch!(:default_pdf_viewer, default_value) }

        it 'still falls back to PDF.js, rather than leaving the PDF unshown' do
          allow(presenter).to receive(:file_set_presenters).and_return([pdf])

          expect(presenter.show_pdf_viewer?).to be(true)
        end
      end

      it 'defers to super when there is no PDF either' do
        allow(presenter).to receive(:file_set_presenters).and_return([image])

        expect(presenter.show_pdf_viewer?).to be_falsey
      end
    end

    context 'when an IIIF viewer is chosen for an unsplit PDF under IIIF Print' do
      let(:selected_viewer) { 'clover' }
      let(:default_value) { Flipflop::FeatureSet.current.feature(:default_pdf_viewer).default }

      before { test_strategy.switch!(:default_pdf_viewer, false) }
      after { test_strategy.switch!(:default_pdf_viewer, default_value) }

      it 'falls back to PDF.js' do
        allow(presenter).to receive_messages(representative_id: '1',
                                             representative_presenter: double('file_set_presenter'),
                                             file_set_presenters: [pdf],
                                             iiif_presentable_member_presenters: [pdf],
                                             child_works_viewable?: false)

        expect(presenter.show_pdf_viewer?).to be(true)
      end
    end

    context 'when an IIIF viewer is chosen and can show the work' do
      let(:selected_viewer) { 'clover' }

      it 'defers to super' do
        allow(presenter).to receive(:iiif_viewer?).and_return(true)
        allow(presenter).to receive(:file_set_presenters).and_return([pdf])

        expect(presenter.show_pdf_viewer?).to be_falsey
      end
    end

    context 'when no viewer is chosen' do
      it 'defers to super' do
        allow(presenter).to receive(:file_set_presenters).and_return([pdf])

        expect(presenter.show_pdf_viewer?).to be_falsey
      end
    end
  end
end
