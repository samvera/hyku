# frozen_string_literal: true

namespace :profiling do
  desc 'Profile a block of Ruby with StackProf; dumps a flamegraph-viewable file to tmp/profiling/'
  task :stackprof, [:label] => :environment do |_t, args|
    require 'stackprof'
    label = args[:label] || Time.now.to_i.to_s
    out = Rails.root.join('tmp', 'profiling', "#{label}.dump")
    FileUtils.mkdir_p(out.dirname)

    StackProf.run(mode: :wall, out: out.to_s, raw: true) do
      # Edit this block to exercise the code path you want profiled, e.g.:
      #   Hyku::WorkShowPresenter.new(...).some_slow_method
    end

    puts "Wrote #{out}"
    puts "View with: bundle exec stackprof --flamegraph #{out}"
  end
end
