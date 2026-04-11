# frozen_string_literal: true

require 'fileutils'

# When A11Y_ARTIFACTS is set (e.g. 1 or true), write URL, HTML, and axe JSON under tmp/a11y/
# for each example tagged :a11y (feature specs with Capybara + Chrome).
FileUtils.mkdir_p(Rails.root.join('tmp', 'a11y')) if ENV['A11Y_ARTIFACTS'].present?

RSpec.configure do |config|
  config.after(:each, a11y: true) do |example|
    next if ENV['A11Y_ARTIFACTS'].blank?
    next unless example.metadata[:type] == :feature
    next unless defined?(page)

    begin
      current = page.current_url
    rescue StandardError
      next
    end

    dir = Rails.root.join('tmp', 'a11y')
    FileUtils.mkdir_p(dir)
    safe = example.full_description.gsub(/[^a-zA-Z0-9_-]+/, '_')[0..120]
    prefix = "#{Time.now.utc.strftime('%Y%m%dT%H%M%S')}_#{safe}"

    File.write(dir.join("#{prefix}.url"), current)

    begin
      File.write(dir.join("#{prefix}.html"), page.html)
    rescue StandardError => e
      File.write(dir.join("#{prefix}.html-error.txt"), e.message)
    end

    begin
      browser = page.driver.browser
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
      File.write(dir.join("#{prefix}.axe.json"), json)
    rescue StandardError => e
      File.write(dir.join("#{prefix}.axe-error.txt"), "#{e.class}: #{e.message}")
    end
  end
end
