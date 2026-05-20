# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Qa::Authorities::Mesh do
  subject(:authority) { described_class.new }

  describe '#search' do
    context 'when the mesh authority does not exist' do
      it 'returns an empty array' do
        expect(authority.search('RNA', nil)).to eq([])
      end
    end

    context 'with a blank query' do
      it 'returns an empty array' do
        expect(authority.search('', nil)).to eq([])
        expect(authority.search(nil, nil)).to eq([])
      end
    end

    context 'with seeded mesh entries' do
      let!(:mesh_authority) { Qa::LocalAuthority.create!(name: 'mesh') }

      def add_entry(label, uri: nil)
        mesh_authority.local_authority_entries.create!(label: label, uri: uri)
      end

      describe 'ranking tiers' do
        before do
          add_entry('mRNA', uri: 'mesh:mrna')
          add_entry('tRNA', uri: 'mesh:trna')
          add_entry('RNA Viruses', uri: 'mesh:rna-viruses')
          add_entry('Avibirnavirus', uri: 'mesh:avi')
          add_entry('RNA', uri: 'mesh:rna')
        end

        it 'returns the exact match first, even when substring matches are alphabetically earlier' do
          results = authority.search('RNA', nil)
          labels = results.map { |r| r[:label] }

          expect(labels.first).to eq('RNA')
        end

        it 'ranks prefix matches before substring matches' do
          results = authority.search('RNA', nil)
          labels = results.map { |r| r[:label] }

          rna_idx = labels.index('RNA')
          rna_viruses_idx = labels.index('RNA Viruses')
          mrna_idx = labels.index('mRNA')

          expect(rna_idx).to be < rna_viruses_idx
          expect(rna_viruses_idx).to be < mrna_idx
        end

        it 'is case-insensitive for the exact-match tier' do
          add_entry('Cancer')
          add_entry('Bile Duct Cancer')

          results = authority.search('cancer', nil)
          expect(results.first[:label]).to eq('Cancer')
        end

        it 'preserves alphabetical ordering within a tier' do
          add_entry('Heart')
          add_entry('Heart Attack')
          add_entry('Heart Failure')
          add_entry('Congenital Heart Disease')

          results = authority.search('heart', nil)
          labels = results.map { |r| r[:label] }

          # Tier 0: exact match
          expect(labels.first).to eq('Heart')

          # Tier 1: prefix matches (alphabetical)
          prefix_labels = labels.select { |l| l.downcase.start_with?('heart') && l != 'Heart' }
          expect(prefix_labels).to eq(prefix_labels.sort)

          # Tier 2: substring (Congenital Heart Disease) comes after the prefix tier
          expect(labels.index('Congenital Heart Disease')).to be > labels.index('Heart Failure')
        end
      end

      describe 'result shape and cap' do
        it 'caps results at 20' do
          25.times { |i| add_entry("Cancer Type #{format('%02d', i)}") }

          results = authority.search('cancer', nil)
          expect(results.size).to eq(20)
        end

        it 'returns id/label/value triples and falls back to label when uri is blank' do
          add_entry('Heart', uri: 'mesh:heart')
          add_entry('Heart Attack', uri: nil)

          results = authority.search('heart', nil)
          heart = results.find { |r| r[:label] == 'Heart' }
          attack = results.find { |r| r[:label] == 'Heart Attack' }

          expect(heart).to include(id: 'mesh:heart', label: 'Heart', value: 'Heart')
          expect(attack).to include(id: 'Heart Attack', label: 'Heart Attack', value: 'Heart Attack')
        end
      end
    end
  end
end
