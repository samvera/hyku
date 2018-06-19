require 'rails_helper'

RSpec.describe WorkDownloadStat, type: :model do
  let(:work) { create(:work_with_one_file) }
  let(:fs) { FileSet.find(work.file_sets[0].id) }
  let(:existing_record) do
    WorkDownloadStat.create(work_uid: fs.parent.id,
                            title: fs.parent.title.first,
                            owner_id: ::User.find_by(email: fs.depositor).id)
  end

  describe '#log_download' do
    it 'adds 1 to the downloads field when the Work is downloaded' do
      r = existing_record
      WorkDownloadStat.new.log_download(fs)
      expect(r.reload.downloads).to eq 1
    end
    it 'raises an error if the argument is not a file_set' do
      expect { WorkDownloadStat.new.log_download(work) }.to raise_error(TypeError)
    end
    it 'records the datetime when the Work was downloaded' do
      r = existing_record
      WorkDownloadStat.new.log_download(fs)
      expect(r.reload.date[0]).to be_within(0.1).of(Time.now.utc)
    end
  end

  describe '#current_work_stats' do
    it 'finds a record when it exists' do
      r = existing_record
      expect(WorkDownloadStat.new.current_work_stats(fs)).to eq(r)
    end
    it 'creates a record when there is none yet for the specified Work' do
      expect(WorkDownloadStat.new.current_work_stats(fs).id).to eq(WorkDownloadStat.last.id)
    end

    context "when creating a new record" do
      it 'assigns a work_uid which is the same as the corresponding Work id' do
        expect(WorkDownloadStat.new.current_work_stats(fs).work_uid).to eq(work.id)
      end
      it 'assigns an owner_id' do ## TO DO: who should be the owner? currently is the `depositor`
        expect(WorkDownloadStat.new.current_work_stats(fs).owner_id).not_to be_nil
      end
      it 'has 0 downloads' do
        expect(WorkDownloadStat.new.current_work_stats(fs).downloads).to eq 0
      end
      it 'does not create duplicates' do
        r = existing_record
        stats = WorkDownloadStat.new.current_work_stats(fs)
        expect(stats.id).to eq(r.id)
      end
    end
  end
end
