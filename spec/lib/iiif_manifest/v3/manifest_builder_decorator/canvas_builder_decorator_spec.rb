# frozen_string_literal: true

RSpec.describe IIIFManifest::V3::ManifestBuilderDecorator::CanvasBuilderDecorator, type: :decorator do
  let(:record) { double('Record', id: 123, parent_title_tesim: 'I am the parent') }
  let(:parent) { double('Parent', manifest_url: 'http://test.host/books/book-77/manifest') }
  let(:builder) do
    IIIFManifest::V3::ManifestBuilder::CanvasBuilder.new(
      record,
      parent,
      iiif_canvas_factory: IIIFManifest::V3::ManifestBuilder::IIIFManifest::Canvas,
      content_builder: '',
      choice_builder: '',
      annotation_content_builder: '',
      iiif_annotation_page_factory: IIIFManifest::V3::ManifestBuilder::IIIFManifest::AnnotationPage,
      thumbnail_builder_factory: '',
      placeholder_canvas_builder_factory: ''
    )
  end
  before { allow(record).to receive(:[]) }
  it 'can run a test' do
    builder.send(:apply_record_properties)
    expect(builder.method(:apply_record_properties).owner).to eq(IIIFManifest::V3::ManifestBuilderDecorator::CanvasBuilderDecorator)
  end
end
