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
end
