# frozen_string_literal: true

RSpec.describe Hyku::Admin::Group::NavigationPresenter do
  let(:active_css_class) { described_class::Tab::ACTIVE_CSS_CLASS }
  let(:base_params) do
    {
      controller: 'admin/groups',
      id: 1
    }
  end

  context 'edit page' do
    subject { presenter.tabs }

    let(:action) { 'edit' }
    let(:params) { base_params.merge(action:) }
    let(:presenter) { described_class.new(params:) }

    it 'has 4 tabs' do
      expect(subject.count).to be(4)
    end

    it 'has the edit tab marked as active' do
      expect(subject.count { |tab| tab.css_class == active_css_class && tab.action == action }).to be(1)
    end
  end

  context 'members page' do
    subject { presenter.tabs }

    let(:action) { 'index' }
    let(:params) { base_params.merge(controller: 'admin/group_users', action:) }
    let(:presenter) { described_class.new(params:) }

    it 'has 4 tabs' do
      expect(subject.count).to be(4)
    end

    it 'has the members tab marked as active' do
      expect(subject.count { |tab| tab.css_class == active_css_class && tab.action == action }).to be(1)
    end
  end

  context 'roles page' do
    subject { presenter.tabs }

    let(:action) { 'index' }
    let(:params) { base_params.merge(controller: 'admin/group_roles', action:) }
    let(:presenter) { described_class.new(params:) }

    it 'has 4 tabs' do
      expect(subject.count).to be(4)
    end

    it 'has the roles tab marked as active' do
      expect(subject.count { |tab| tab.css_class == active_css_class && tab.action == action }).to be(1)
    end
  end

  context 'remove page' do
    subject { presenter.tabs }

    let(:action) { 'remove' }
    let(:params) { base_params.merge(action:) }
    let(:presenter) { described_class.new(params:) }

    it 'has 4 tabs' do
      expect(subject.count).to be(4)
    end

    it 'has the remove tab marked as active' do
      expect(subject.count { |tab| tab.css_class == active_css_class && tab.action == action }).to be(1)
    end
  end
end
