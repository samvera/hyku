# frozen_string_literal: true

RSpec.describe Hyku::MenuPresenter do
  let(:instance) { described_class.new(context) }
  let(:context) { double }

  # The class the dashboard sidebar actually instantiates, so what it reports is what
  # a user sees. Hyrax::MenuPresenterDecorator answers the same question, but a
  # subclass overriding the method wins over a module prepended to its parent.
  describe '#show_task?' do
    subject { instance.show_task? }

    before do
      allow(instance.view_context).to receive(:can?).and_return(false)
      allow(instance.view_context).to receive(:can?).with(*permitted).and_return(true)
    end

    context 'for a user who can only view the vocabularies' do
      let(:permitted) { [:view, :controlled_vocabularies] }

      # A depositor gets :view through can_import_works?, and the vocabularies link is
      # the only Tasks entry they have. Without this the section is suppressed and the
      # page is reachable only by typing the url.
      it { is_expected.to be true }
    end

    context 'for a user who can review submissions' do
      let(:permitted) { [:review, :submissions] }

      it { is_expected.to be true }
    end

    context 'for a user who can read users' do
      let(:permitted) { [:read, User] }

      it { is_expected.to be true }
    end

    context 'for a user who can read groups' do
      let(:permitted) { [:read, Hyrax::Group] }

      it { is_expected.to be true }
    end

    context 'for a user who can read the admin dashboard' do
      let(:permitted) { [:read, :admin_dashboard] }

      it { is_expected.to be true }
    end

    context 'for a user with none of those' do
      let(:permitted) { [:something, :unrelated] }

      it { is_expected.to be false }
    end
  end
end
