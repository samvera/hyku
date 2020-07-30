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

      allow(Settings).to receive(:contact_email_to).and_return('hyrax@email.com')
    end

    context 'no email set' do
      before do
        site = double(Site.new, contact_email: '')
        allow(Site).to receive(:instance).and_return(site)
      end
      it 'uses the hyrax setting' do
        expect(subject.headers[:to]).to eq('hyrax@email.com')
      end
    end
    context 'site email set' do
      before do
        site = double(Site.new, contact_email: 'setting@email.com')
        allow(Site).to receive(:instance).and_return(site)
      end
      it 'uses the Site email' do
        expect(subject.headers[:to]).to eq('setting@email.com')
      end
    end
  end
end
