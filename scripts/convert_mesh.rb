#!/usr/bin/env ruby
# frozen_string_literal: true
# Script to convert MeSH .bin file to plain text format
# Usage: ruby convert_mesh.rb d2025.bin mesh_terms.txt

require 'optparse'

def convert_mesh_bin_to_text(input_file, output_file)
  puts "Converting #{input_file} to #{output_file}..."

  File.open(output_file, 'w') do |output|
    File.foreach(input_file) do |line|
      # Look for lines that start with "MH = " (MeSH Heading)
      if line.strip.start_with?('MH = ')
        # Extract the term after "MH = "
        term = line.strip.gsub(/^MH = /, '').strip
        # Remove any trailing punctuation or formatting
        term = term.gsub(/[;\.]$/, '')
        # Only include if it's not empty and doesn't contain special characters
        output.puts term if !term.empty? && !term.include?('*') && !term.include?('/')
      end
    end
  end

  puts "Conversion complete! Check #{output_file}"
end

# Parse command line arguments
input_file = ARGV[0]
output_file = ARGV[1] || 'mesh_terms.txt'

if input_file.nil?
  puts "Usage: ruby convert_mesh.rb <input.bin> [output.txt]"
  puts "Example: ruby convert_mesh.rb d2025.bin mesh_terms.txt"
  exit 1
end

unless File.exist?(input_file)
  puts "Error: Input file #{input_file} not found"
  exit 1
end

convert_mesh_bin_to_text(input_file, output_file)
