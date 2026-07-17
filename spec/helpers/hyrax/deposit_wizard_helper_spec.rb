# frozen_string_literal: true

RSpec.describe Hyrax::DepositWizardHelper, type: :helper do
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
