# frozen_string_literal: true

require 'fileutils'

# When A11Y_ARTIFACTS is set (e.g. 1 or true), write URL, HTML, and axe JSON under tmp/a11y/
# for each example tagged :a11y (feature specs with Capybara + Chrome).
#
# Written from HykuAccessibility::Helpers#expect_hyku_primary_content_axe_clean right after
# be_axe_clean so URL, DOM, and axe are still on the session (remote Selenium often shows
# about:blank in after(:each) even before reset_sessions!).
FileUtils.mkdir_p(Rails.root.join('tmp', 'a11y')) if ENV['A11Y_ARTIFACTS'].present?

RSpec.configure do |config|
  # RSpec.current_example is often nil inside included helper methods after matchers run; keep a
  # handle to RSpec::Core::Example for artifact naming and metadata.
  # Use type: :feature + metadata check so nested contexts always match (same as infer_spec_type).
  config.before(:each, type: :feature) do |ex|
    next unless ex.metadata[:a11y] || ex.metadata['a11y']

    @hyku_a11y_rspec_example = ex
  end
end

module HykuAccessibility
  module A11yArtifacts
    module_function

    def write_for_example(example)
      return if ENV['A11Y_ARTIFACTS'].blank?
      if example.nil?
        warn '[A11Y_ARTIFACTS] Skipped snapshot: example handle was nil (before hook should set @hyku_a11y_rspec_example)'
        return
      end

      a11y = example.metadata[:a11y] || example.metadata['a11y']
      return unless a11y
      return unless example.metadata[:type] == :feature

      # Do not use defined?(page) here: this method is a module_function, so `page` is not in scope
      # and defined?(page) is always false, which skipped all writes silently.
      session = Capybara.current_session
      current =
        begin
          # Prefer driver URL; Capybara's page.current_url can be about:blank with remote Chrome.
          session.driver.browser.current_url
        rescue StandardError
          begin
            session.current_url
          rescue StandardError
            nil
          end
        end
      if current.blank? || current == 'about:blank'
        warn "[A11Y_ARTIFACTS] Skipped snapshot (no real URL: #{current.inspect}) — #{example.full_description}"
        return
      end

      dir = Rails.root.join('tmp', 'a11y')
      FileUtils.mkdir_p(dir)
      safe = example.full_description.gsub(/[^a-zA-Z0-9_-]+/, '_')[0..120]
      prefix = "#{Time.now.utc.strftime('%Y%m%dT%H%M%S')}_#{safe}"

      File.write(dir.join("#{prefix}.url"), "#{current}\n")

      begin
        File.write(dir.join("#{prefix}.html"), session.html)
      rescue StandardError => e
        File.write(dir.join("#{prefix}.html-error.txt"), e.message)
      end

      begin
        browser = session.driver.browser
        script = <<~JS
          const callback = arguments[arguments.length - 1];
          if (typeof axe === 'undefined') {
            callback(JSON.stringify({ error: 'axe not loaded on page' }));
            return;
          }
          axe.run(document, { runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag21aa'] } })
            .then(results => callback(JSON.stringify(results)));
        JS
        json = browser.execute_async_script(script)
        File.write(dir.join("#{prefix}.axe.json"), "#{json}\n")
      rescue StandardError => e
        File.write(dir.join("#{prefix}.axe-error.txt"), "#{e.class}: #{e.message}\n")
      end
    end
  end
end
