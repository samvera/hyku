# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyrax::IiifAv::DisplaysContent do
  describe '.iiif_audio_labels_and_mime_types' do
    subject { described_class.iiif_audio_labels_and_mime_types }
    it { is_expected.to be_a(Hash) }
  end

  describe '.iiif_video_labels_and_mime_types' do
    subject { described_class.iiif_video_labels_and_mime_types }
    it { is_expected.to be_a(Proc) }
  end

  describe '.iiif_video_url_builder' do
    subject { described_class.iiif_video_url_builder }
    it { is_expected.to be_a(Proc) }
  end
end
