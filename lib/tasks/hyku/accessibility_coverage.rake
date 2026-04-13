# frozen_string_literal: true

require 'open3'
require 'yaml'
require 'json'

namespace :hyku do
  namespace :accessibility do
    desc "A11y test progress: WCAG matrix linkage + count of :a11y RSpec examples (like a coverage report for journeys)"
    task coverage_report: :environment do
      HykuAccessibilityCoverageReport.run
    end
  end
end

class HykuAccessibilityCoverageReport
  class << self
    def run
      new.print
    end
  end

  def initialize
    @root = Rails.root
    @matrix_path = @root.join('docs/accessibility/wcag-2.1-aa-traceability-matrix.yaml')
    @pa11y_sample = @root.join('docs/accessibility/pa11yci.sample.json')
  end

  def print
    puts '=' * 72
    puts 'Hyku accessibility test coverage (progress report)'
    puts '=' * 72
    print_spec_files
    puts
    print_rspec_a11y_count
    puts
    print_matrix_stats
    puts
    print_pa11y_sample_urls
    puts '=' * 72
  end

  private

  def print_spec_files
    files = Dir.glob(@root.join('spec/features/accessibility/**/*_spec.rb')).sort
    puts "Accessibility feature specs (#{files.size} files):"
    files.each { |f| puts "  - #{f.sub(%r{\A#{Regexp.escape(@root.to_s)}/}, '')}" }
  end

  def print_rspec_a11y_count
    puts 'RSpec :a11y examples (dry-run):'
    cmd = ['bundle', 'exec', 'rspec', '--dry-run', '--tag', 'a11y', '--format', 'progress']
    stdout_and_stderr, status = Open3.capture2e(
      { 'RAILS_ENV' => 'test' },
      *cmd,
      chdir: @root.to_s
    )

    unless status.success?
      warn ' (dry-run failed — run from app root with bundle installed)'
      warn stdout_and_stderr.lines.last(5).join
      return
    end

    matches = stdout_and_stderr.scan(/(\d+)\s+examples/)
    if matches.any?
      puts "  #{matches.last.first} examples tagged :a11y"
    else
      warn '  Could not parse example count from rspec output.'
    end
  end

  def print_matrix_stats
    unless @matrix_path.file?
      warn "Matrix not found: #{@matrix_path}"
      return
    end

    data = YAML.load_file(@matrix_path)
    rows = Array(data['criteria'])
    puts "WCAG matrix (#{@matrix_path.relative_path_from(@root)}):"
    puts "  Total criteria rows: #{rows.size}"

    by_coverage = rows.group_by { |r| r['coverage'].to_s }
    puts '  By coverage type:'
    by_coverage.keys.sort.each do |k|
      puts "    #{k}: #{by_coverage[k].size}"
    end

    %w[automated_axe semi_automated].each do |bucket|
      bucket_rows = rows.select { |r| r['coverage'].to_s == bucket }
      next if bucket_rows.empty?

      linked = bucket_rows.count { |r| spec_paths_for(r).any? }
      total = bucket_rows.size
      pct = total.positive? ? (100.0 * linked / total).round(1) : 0.0
      puts "  #{bucket}: #{linked}/#{total} rows list at least one spec (#{pct}% linkage)"

      unlinked = bucket_rows.reject { |r| spec_paths_for(r).any? }
      next if unlinked.empty?

      puts "    Unlinked (add spec paths under specs:):"
      unlinked.each { |r| puts "      - #{r['id']} #{r['name']}" }
    end
  end

  def spec_paths_for(row)
    specs = row['specs']
    return [] if specs.nil?
    return specs if specs.is_a?(Array)

    # legacy single string
    [specs].compact
  end

  def print_pa11y_sample_urls
    unless @pa11y_sample.file?
      puts 'Pa11y sample config: (file not found)'
      return
    end

    begin
      config = JSON.parse(File.read(@pa11y_sample))
      urls = Array(config['urls'])
      puts "Pa11y sample URL targets (#{@pa11y_sample.basename}): #{urls.size} URLs"
      urls.first(5).each { |u| puts "  - #{u}" }
      puts "  (#{urls.size - 5} more…)" if urls.size > 5
    rescue JSON::ParserError => e
      warn "  Could not parse Pa11y sample JSON: #{e.message}"
    end
  end
end
