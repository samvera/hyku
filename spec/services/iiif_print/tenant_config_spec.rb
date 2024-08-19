# frozen_string_literal: true

require 'spec_helper'

##
# Yes good reader this is a lot of modules that have specs; however, they are a cohesive and atomic
# unit.  That is to say they each build towards the feature of "whether or not we use IIIF Print".
#
# So instead of sprinkling these all around, I opted to compartmentalize them in the
# IiifPrint::TenantConfig module.
#
# rubocop:disable RSpec/DescribeClass
RSpec.describe 'Tenant Config for IIIF Print' do
  let!(:test_strategy) { Flipflop::FeatureSet.current.test! }

  after { test_strategy.switch!(:default_pdf_viewer, true) }

  describe IiifPrint::TenantConfig do
    describe '.use_iiif_print?' do
      subject { described_class.use_iiif_print? }

      context 'by default' do
        it { is_expected.to be_falsey }
      end

      context 'when the feature is flipped to false' do
        before { test_strategy.switch!(:default_pdf_viewer, true) }

        it { is_expected.to be_falsey }
      end

      context 'when the feature is flipped to true' do
        before { test_strategy.switch!(:default_pdf_viewer, false) }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe IiifPrint::TenantConfig::DerivativeService do
    let(:fake_service_class) do
      # Creating a class that inherits from the configured service but doesn't do all the antics of
      # that service.  For testing and implementation purposes we must assume the underlying thing
      # works as intended, but are instead testing that we're properly calling things.
      Class.new(described_class.iiif_service_class) do
        def initialize(file_set); end
      end
    end

    let(:file_set) { double(FileSet) }

    let(:instance) { described_class.new(file_set).tap { |i| i.iiif_service_class = fake_service_class } }

    describe '#iiif_service_class' do
      subject { described_class.iiif_service_class }

      it { is_expected.to eq(::IiifPrint::PluggableDerivativeService) }
    end

    describe '#valid?' do
      subject { instance.valid? }

      context 'when the feature is flipped to false' do
        before { test_strategy.switch!(:default_pdf_viewer, true) }

        it { is_expected.to be_falsey }
      end

      context 'when the feature is flipped to true' do
        before { test_strategy.switch!(:default_pdf_viewer, false) }

        it 'delegates to the configured iiif_service' do
          expect(instance.iiif_print_service_instance).to receive(:valid?)
          subject
        end
      end
    end

    describe '#create_derivatives' do
      subject { instance.create_derivatives("filename") }

      context 'when the feature is flipped to false' do
        before { test_strategy.switch!(:default_pdf_viewer, true) }

        it 'raises an error' do
          expect { subject }.to raise_error(IiifPrint::TenantConfig::LeakyAbstractionError)
        end
      end

      context 'when the feature is flipped to true' do
        before { test_strategy.switch!(:default_pdf_viewer, false) }
        it 'delegates to the configured iiif_service' do
          expect(instance.iiif_print_service_instance).to receive(:create_derivatives)
          subject
        end
      end
    end

    describe '#cleanup_derivatives' do
      subject { instance.cleanup_derivatives }

      context 'when the feature is flipped to false' do
        before { test_strategy.switch!(:default_pdf_viewer, true) }

        it 'raises an error' do
          expect { subject }.to raise_error(IiifPrint::TenantConfig::LeakyAbstractionError)
        end
      end

      context 'when the feature is flipped to true' do
        before { test_strategy.switch!(:default_pdf_viewer, false) }
        it 'delegates to the configured iiif_service' do
          expect(instance.iiif_print_service_instance).to receive(:cleanup_derivatives)
          subject
        end
      end
    end
  end

  describe IiifPrint::TenantConfig::PdfSplitter do
    describe '.iiif_print_splitter' do
      subject { described_class.iiif_print_splitter }

      it { is_expected.to eq(::IiifPrint::SplitPdfs::PagesToJpgsSplitter) }
    end

    describe '.call' do
      subject { described_class.call(:arg) }

      context 'when the feature is flipped to false' do
        before { test_strategy.switch!(:default_pdf_viewer, true) }

        it { is_expected.to eq([]) }
      end

      context 'when the feature is flipped to true' do
        before { test_strategy.switch!(:default_pdf_viewer, false) }

        it 'delegates to the configured .iiif_print_splitter' do
          expect(described_class.iiif_print_splitter).to receive(:call).with(:arg)
          subject
        end
      end
    end
  end

  describe IiifPrint::TenantConfig::SkipSplittingPdfService do
    describe '.conditionally_enqueue' do
      subject { described_class.conditionally_enqueue }

      it { is_expected.to eq(:tenant_does_not_split_pdfs) }
    end
  end

  describe Hyrax::Actors::FileSetActor do
    let(:instance) { described_class.new(:file_set, :user) }

    ##
    # The purpose of this spec is to demonstrate that load sequence of modules correctly evaluates
    describe '#service' do
      subject { instance.service }

      context 'when the feature is flipped to false' do
        before { test_strategy.switch!(:default_pdf_viewer, true) }

        it { is_expected.to eq(IiifPrint::TenantConfig::SkipSplittingPdfService) }
      end

      context 'when the feature is flipped to true' do
        before { test_strategy.switch!(:default_pdf_viewer, false) }

        it { is_expected.to eq(IiifPrint::SplitPdfs::ChildWorkCreationFromPdfService) }
      end
    end
  end

  ##
  # Much like the Hyrax::Actors::FileSetActor, we need to ensure that we've registered derivatives
  # in the correct manner.
  #
  # see config/application.rb
  describe Hyrax::DerivativeService do
    describe '.services' do
      subject { described_class.services }

      it { is_expected.to match_array([IiifPrint::TenantConfig::DerivativeService, Hyrax::FileSetDerivativesService]) }
    end
  end

  describe Hyrax::WorkShowPresenter do
    let(:instance) { described_class.new(:solr_doc, :ability) }

    describe '#iiif_media_predicates' do
      subject { instance.iiif_media_predicates }

      context 'when the feature is flipped to false' do
        before { test_strategy.switch!(:default_pdf_viewer, true) }

        it { is_expected.to eq(%i[image? audio? video?]) }
      end

      context 'when the feature is flipped to true' do
        before { test_strategy.switch!(:default_pdf_viewer, false) }

        it { is_expected.to eq(%i[image? audio? video? pdf?]) }
      end
    end
  end
end
# rubocop:enable RSpec/DescribeClass
