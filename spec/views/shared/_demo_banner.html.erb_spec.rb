# frozen_string_literal: true

RSpec.describe 'shared/_demo_banner.html.erb', type: :view do
  let(:account) do
    FactoryBot.build(:account, :public_demo_tenant, last_reset_at:).tap do |acct|
      acct.demo_acceptable_use_url = acceptable_use_url
    end
  end
  let(:last_reset_at) { nil }
  let(:acceptable_use_url) { nil }

  before do
    allow(view).to receive(:current_account).and_return(account)
    render partial: 'shared/demo_banner'
  end

  context 'on a public demo tenant' do
    it 'shows the demo environment banner with the running version' do
      expect(rendered).to have_css('#demo-banner')
      expect(rendered).to have_content('Demo environment')
      expect(rendered).to have_content("v#{Hyku::VERSION}")
    end

    it 'states the reset schedule' do
      expect(rendered).to have_content('reset nightly')
    end

    it 'has an accessible dismiss control' do
      expect(rendered).to have_css('button.close[data-dismiss="alert"][aria-label]')
    end

    context 'before the first reset' do
      it 'says the tenant has not been reset yet' do
        expect(rendered).to have_content('has not been reset yet')
      end
    end

    context 'with a recorded reset' do
      let(:last_reset_at) { Time.zone.parse('2026-07-05 08:00') }

      it 'shows the last reset time' do
        expect(rendered).to have_content('Last reset')
      end
    end

    context 'with an acceptable use link configured' do
      let(:acceptable_use_url) { 'https://example.org/acceptable-use' }

      it 'links to the acceptable use page' do
        expect(rendered).to have_link(href: 'https://example.org/acceptable-use')
      end
    end

    context 'without an acceptable use link' do
      it 'renders no acceptable use link' do
        expect(rendered).not_to have_css('#demo-banner a.alert-link')
      end
    end
  end

  context 'on a regular tenant' do
    let(:account) { FactoryBot.build(:account) }

    it 'renders nothing' do
      expect(rendered.strip).to be_empty
    end
  end
end
