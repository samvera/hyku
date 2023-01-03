# frozen_string_literal: true

RSpec.describe Role, type: :model do
  describe '.global' do
    let!(:role_a) { described_class.create(name: :a) }
    let!(:role_b) { described_class.create(name: :b, resource: Site.instance) }
    let!(:role_c) { described_class.create(name: :c, resource: Site.instance) }

    it 'selects only the global roles' do
      expect(described_class.site).to match_array [role_b, role_c]
    end
  end

  describe '#set_sort_value' do
    it 'gets called before creation' do
      new_role = Role.new(name: 'new_role', resource: Site.instance)

      expect(new_role).to receive(:set_sort_value).once
      new_role.save!
    end

    context 'when creating the :admin role' do
      let(:role) { FactoryBot.create(:role, :admin) }

      it 'sets :sort_value to 0' do
        expect(role.sort_value).to eq(0)
      end
    end

    context 'when creating a manager role' do
      let(:role) { FactoryBot.create(:role, :collection_manager) }

      it 'sets :sort_value to 1' do
        expect(role.sort_value).to eq(1)
      end
    end

    context 'when creating an editor role' do
      let(:role) { FactoryBot.create(:role, :work_editor) }

      it 'sets :sort_value to 2' do
        expect(role.sort_value).to eq(2)
      end
    end

    context 'when creating an depositor role' do
      let(:role) { FactoryBot.create(:role, :work_depositor) }

      it 'sets :sort_value to 3' do
        expect(role.sort_value).to eq(3)
      end
    end

    context 'when creating an reader role' do
      let(:role) { FactoryBot.create(:role, :user_reader) }

      it 'sets :sort_value to 4' do
        expect(role.sort_value).to eq(4)
      end
    end

    context 'when creating any other role' do
      let(:role) { FactoryBot.create(:role, :site_role, name: 'test') }

      it 'sets :sort_value to 99' do
        expect(role.sort_value).to eq(99)
      end
    end
  end
end
