# frozen_string_literal: true

RSpec.describe CreateGroupAndAddMembersJob, type: :job do
  subject(:job) { described_class.new(work.id) }

  let(:work) do
    work = FactoryBot.create(:cdl, title: ['Test CDL'])
    work.ordered_members << file_set
    work.save
    work
  end
  let(:split_work_factory) { work.iiif_print_config.pdf_split_child_model.to_s.underscore }
  let(:file_set) { FactoryBot.create(:file_set, title: ['Test File Set']) }
  let(:work_page_1) { FactoryBot.create(split_work_factory, title: ["#{work.id} - #{work.title.first} Page 1"]) }
  let(:work_page_2) { FactoryBot.create(split_work_factory, title: ["#{work.id} - #{work.title.first} Page 2"]) }
  let(:file_set_page_1) { FactoryBot.create(:file_set, title: ["page1.jpg"]) }
  let(:file_set_page_2) { FactoryBot.create(:file_set, title: ["page2.jpg"]) }

  before { allow_any_instance_of(FileSet).to receive(:page_count).and_return(["2"]) }

  describe '#perform' do
    context 'when has all its child works' do
      before do
        work.ordered_members << work_page_1
        work.ordered_members << work_page_2
        work.save
        work_page_1.ordered_members << file_set_page_1
        work_page_1.save
        work_page_2.ordered_members << file_set_page_2
        work_page_2.save
      end

      it 'creates a group' do
        expect { job.perform(work.id) }.to change { Hyrax::Group.count }.by(1)
      end

      it 'assigns the group to the work read_groups' do
        job.perform(work.id)

        expect(work.reload.read_groups).to eq([work.id])
      end

      it "assigns the group to the read_groups of each work's member" do
        job.perform(work.id)

        expect(work_page_1.reload.read_groups).to eq([work.id])
        expect(work_page_2.reload.read_groups).to eq([work.id])
      end

      it "assigns the group to the read_groups of each work's member's member" do
        job.perform(work.id)

        expect(file_set_page_1.reload.read_groups).to eq([work.id])
        expect(file_set_page_2.reload.read_groups).to eq([work.id])
      end
    end

    context 'when does not have all its child works' do
      before do
        work.ordered_members << work_page_1
        work.save
      end

      it 'retries the job' do
        expect(described_class).to receive(:set).with(wait: 10.minutes).and_return(described_class)

        job.perform(work.id)
      end

      it 'does not retry the job more than 5 times' do
        expect(described_class).not_to receive(:set)

        job.perform(work.id, 6)
      end
    end
  end
end
