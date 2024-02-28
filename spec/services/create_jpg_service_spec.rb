# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreateJpgService do
  let(:pdf_file) do
    create(:uploaded_file,
           file: File.open(::Rails.root.join('spec/fixtures/pdf/archive.pdf')))
  end

  it 'takes in a pdf and returns a file with jpgs for each page' do
    files = CreateJpgService.new([pdf_file]).create_jpgs
    expect(files).not_to include(pdf_file)
    expect(files.count).not_to be_nil
  end
end
