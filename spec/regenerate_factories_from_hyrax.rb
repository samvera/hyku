# frozen_string_literal: true

# The purpose of this script is require Hyrax factories and show a bit of what they define.  The
# named factories are only part of the story.

BEGIN_GENERATED_SECTION = "# BEGIN AUTO-GENERATED SECTION"
END_GENERATED_SECTION = "# END AUTO-GENERATED SECTION"

command = File.basename(__FILE__)
HYRAX_PATH = ENV.fetch('HYRAX_PATH') { Hyrax::Engine.root.to_s }

# This assumes that we are not working with sub-directories
Dir.glob(File.join(HYRAX_PATH, "spec/factories/*.rb")).each do |filename|
  basename = File.basename(filename)

  hyku_path = File.expand_path("./factories/#{basename}", __dir__)

  next if File.exist?(hyku_path)

  factories = File.read(filename).scan(%r{factory :(\w+)}).flatten

  # This script doesn't do much now regarding the auto-generated section.  But I'm planning ahead.
  File.open(hyku_path, "w+") do |f|
    f.puts "# frozen_string_literal: true"
    f.puts ""
    f.puts BEGIN_GENERATED_SECTION
    f.puts "# Anything between the BEGIN and END section is subject to being replaced via #{command}"
    f.puts ""
    f.puts "require Hyrax::Root.join('spec/factories/#{basename}').to_s"
    f.puts ""
    f.puts "# Defined Factories:"
    factories.each do |factory|
      f.puts "# - define :#{factory}"
    end
    f.puts ""
    f.puts END_GENERATED_SECTION
  end
end
