# frozen_string_literal: true

RSpec.describe DigitalCollectionFileSetHelper, type: :helper do
  let(:presenter) do
    double('file set', depositor: '', date_uploaded: '2026-09-03', date_modified: nil, fixity_check_status: 'Passed',
                       mime_type: ['image/jpeg'], file_size: ['4404019'], width: ['6000'], height: ['4500'])
  end

  describe '#dc_file_detail_rows' do
    it 'lists the facts in plain words and skips the blank ones' do
      allow(helper).to receive(:link_to_profile).and_return('')

      expect(helper.dc_file_detail_rows(presenter)).to eq([['Date uploaded', 'September 3, 2026'], ['Fixity check', 'Passed'],
                                                           ['File format', 'image/jpeg'], ['File size', '4.2 MB'],
                                                           ['Dimensions', '6000 × 4500 px']])
    end
  end

  describe '#dc_long_date' do
    it "writes a date or a time in the reader's date format" do
      expect(I18n.with_locale(:de) { helper.dc_long_date('2026-09-03') }).to eq('3. September 2026')
      expect(helper.dc_long_date(Time.zone.local(2026, 9, 3, 15))).to eq('September 3, 2026')
    end

    it 'gives nothing for a blank or unreadable value' do
      expect(helper.dc_long_date('')).to be_nil
      expect(helper.dc_long_date('not a date')).to be_nil
    end
  end
end
