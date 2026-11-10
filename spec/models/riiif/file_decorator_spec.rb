# frozen_string_literal: true

RSpec.describe Riiif::File do
  let(:transformation) do
    IIIF::Image::OptionDecoder.decode(region: 'full', size: '50,', rotation: '0', quality: 'default', format: 'png')
  end

  it 'renders the placeholder riiif builds without an id for an unauthorized or missing image' do
    placeholder = described_class.new(Riiif.unauthorized_image.to_s)

    expect(placeholder.extract(transformation, placeholder.info)).to start_with("\x89PNG".b)
  end

  it 'reads a resolved file under its lock' do
    file = described_class.new(Riiif.unauthorized_image.to_s, id: 'fs-1/files/f-1')
    lock = Concurrent::ReadWriteLock.new
    allow(Riiif::Image.file_resolver).to receive(:file_locks).and_return('fs-1/files/f-1' => lock)
    allow(lock).to receive(:with_read_lock).and_call_original

    file.extract(transformation, file.info)

    expect(lock).to have_received(:with_read_lock)
  end
end
