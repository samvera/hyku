# frozen_string_literal: true

RSpec.describe Hyrax::DepositWizardHelper, type: :helper do
  describe '#guided_replaces_standard?' do
    let(:capabilities) { Hyku::DepositWizard.config.capabilities }

    it 'delegates to the config capability' do
      allow(capabilities).to receive(:guided_replaces_standard?).and_return(true)
      expect(helper.guided_replaces_standard?).to be(true)

      allow(capabilities).to receive(:guided_replaces_standard?).and_return(false)
      expect(helper.guided_replaces_standard?).to be(false)
    end
  end

  describe '#show_guided_deposit_button? / #show_standard_deposit_button?' do
    let(:config) { Hyku::DepositWizard.config }

    it 'each reflects its own enable flag independently' do
      allow(config).to receive(:enabled?).and_return(true)
      allow(config).to receive(:standard_deposit_button?).and_return(false)
      expect(helper.show_guided_deposit_button?).to be(true)
      expect(helper.show_standard_deposit_button?).to be(false)

      allow(config).to receive(:enabled?).and_return(false)
      allow(config).to receive(:standard_deposit_button?).and_return(true)
      expect(helper.show_guided_deposit_button?).to be(false)
      expect(helper.show_standard_deposit_button?).to be(true)
    end
  end

  describe '#standard_deposit_target' do
    it 'targets the select-work modal when several types are creatable' do
      href, data = helper.standard_deposit_target(many: true, first_type: GenericWorkResource)
      expect(href).to eq('#')
      expect(data).to include(behavior: 'select-work', 'create-type' => 'single')
    end

    it 'links straight to the only creatable type otherwise' do
      href, data = helper.standard_deposit_target(many: false, first_type: GenericWorkResource)
      expect(href).to eq(new_polymorphic_path([main_app, GenericWorkResource]))
      expect(data).to eq({})
    end
  end

  describe '#deposit_new_work_target' do
    let(:capabilities) { Hyku::DepositWizard.config.capabilities }

    context 'when guided replaces the standard path' do
      before { allow(capabilities).to receive(:guided_replaces_standard?).and_return(true) }

      it 'targets the wizard regardless of work-type count' do
        href, data = helper.deposit_new_work_target(many: true, first_type: GenericWorkResource)
        expect(href).to eq(main_app.deposit_wizard_path)
        expect(data).to eq({})
      end
    end

    context 'when guided does not replace the standard path' do
      before { allow(capabilities).to receive(:guided_replaces_standard?).and_return(false) }

      it 'targets the select-work modal when several types are creatable' do
        href, data = helper.deposit_new_work_target(many: true, first_type: GenericWorkResource)
        expect(href).to eq('#')
        expect(data).to include(behavior: 'select-work', 'create-type' => 'single')
      end

      it 'links straight to the only creatable type otherwise' do
        href, data = helper.deposit_new_work_target(many: false, first_type: GenericWorkResource)
        expect(href).to eq(new_polymorphic_path([main_app, GenericWorkResource]))
        expect(data).to eq({})
      end
    end
  end

  describe '#visibility_summary' do
    it 'renders an embargo as a transitional phrase with badge HTML' do
      html = helper.visibility_summary('visibility' => 'embargo',
                                       'visibility_during_embargo' => 'restricted',
                                       'visibility_after_embargo' => 'open',
                                       'embargo_release_date' => '2099-01-01')

      expect(html).to be_html_safe
      # The visibility badges are intentionally rendered as HTML.
      expect(html).to include('<span class="badge')
      expect(html).to include('2099-01-01')
    end

    it 'escapes a malicious date value rather than rendering it as HTML' do
      html = helper.visibility_summary('visibility' => 'embargo',
                                       'visibility_during_embargo' => 'restricted',
                                       'visibility_after_embargo' => 'open',
                                       'embargo_release_date' => '<script>alert(1)</script>')

      expect(html).not_to include('<script>alert(1)</script>')
      expect(html).to include('&lt;script&gt;')
    end
  end
end
