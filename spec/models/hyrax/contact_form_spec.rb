# frozen_string_literal: true

RSpec.describe Hyrax::ContactForm, type: :model do
  describe 'headers' do
    before do
      subject do
        described_class.new(
          subject: "subject",
          from: "from@email.com"
        )
      end

      allow(Hyrax.config).to receive(:contact_email).and_return('hyrax@email.com')
    end

    context 'no email set' do
      before do
        site = double(Site.new)
        account = Account.new
        allow(Site).to receive(:instance).and_return(site)
        allow(Site).to receive(:account).and_return(account)
      end
      it 'uses the hyrax setting' do
        expect(subject.headers[:to]).to eq('change-me-in-settings@example.com')
      end
    end
    context 'site email set' do
      before do
        site = double(Site.new)
        account = Account.new
        account.contact_email_to = 'setting@email.com'
        allow(Site).to receive(:instance).and_return(site)
        allow(Site).to receive(:account).and_return(account)
      end
      it 'uses the Site email' do
        expect(subject.headers[:to]).to eq('setting@email.com')
      end
    end
  end
end
