# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HeritageHelper, type: :helper do
  describe '#hrt_file_set_ids' do
    let(:presenter) { double(authorized_file_set_ids: (1..25).map { |i| "fs-#{i}" }) }

    it 'pages at ten entries' do
      paged = helper.hrt_file_set_ids(presenter)

      expect(paged.total_count).to eq(25)
      expect(paged.count).to eq(10)
      expect(paged.total_pages).to eq(3)
    end

    it 'clamps an out of range page back to the last page' do
      allow(helper).to receive(:params).and_return({ files_page: '99' })

      expect(helper.hrt_file_set_ids(presenter).current_page).to eq(3)
    end

    it 'ignores junk page params' do
      allow(helper).to receive(:params).and_return({ files_page: 'DROP TABLE' })

      expect(helper.hrt_file_set_ids(presenter).current_page).to eq(1)
    end
  end
end
