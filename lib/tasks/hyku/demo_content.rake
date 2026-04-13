# frozen_string_literal: true

namespace :hyku do
  namespace :demo_content do
    desc "Seed a11y demo tenant, Solr-indexed work/collection, and e2e/a11y-routes/a11y-routes.manifest.json for Playwright"
    task seed: :environment do
      require Rails.root.join("lib", "hyku", "demo_a11y_content_seed.rb").to_s
      Hyku::DemoA11yContentSeed.run!
    end
  end
end
