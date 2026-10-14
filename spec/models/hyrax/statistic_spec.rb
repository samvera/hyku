# frozen_string_literal: true

RSpec.describe Hyrax::Statistic do
  let(:file) { double(id: 'file-1') } # rubocop:disable RSpec/VerifiedDoubles

  def advance(date)
    FileViewStat.send(:advance_zero_marker, file, :views, date, nil)
  end

  describe '.advance_zero_marker' do
    context 'when a zero-count marker already exists' do
      let!(:marker) { FileViewStat.create!(file_id: 'file-1', date: 5.days.ago.to_date, views: 0) }

      it 'moves the marker to a later zero-count date instead of raising' do
        expect { advance(2.days.ago.to_date) }.not_to raise_error
        expect(marker.reload.date.to_date).to eq 2.days.ago.to_date
      end

      it 'leaves the marker where it is for an earlier date' do
        advance(8.days.ago.to_date)
        expect(marker.reload.date.to_date).to eq 5.days.ago.to_date
      end
    end

    context 'when there is no marker yet' do
      it 'creates one at the given date' do
        expect { advance(3.days.ago.to_date) }.to change(FileViewStat, :count).by(1)
        expect(FileViewStat.last.date.to_date).to eq 3.days.ago.to_date
      end
    end
  end
end
