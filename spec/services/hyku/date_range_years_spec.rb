# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyku::DateRangeYears do
  describe '.call' do
    it 'reads a bare year' do
      expect(described_class.call('1911')).to eq [1911]
    end

    it 'reads a year and month' do
      expect(described_class.call('1962-11')).to eq [1962]
    end

    it 'reads a full date' do
      expect(described_class.call('1954-01-14')).to eq [1954]
    end

    it 'reads every value it is given, sorted and deduplicated' do
      expect(described_class.call('1968-10-09', '1911', '1911')).to eq [1911, 1968]
    end

    it 'flattens nested values so an indexer can pass array-valued properties' do
      expect(described_class.call([['1911'], ['1962-11']])).to eq [1911, 1962]
    end

    it 'drops the "[]" sentinel Hyrax writes for an empty attribute' do
      expect(described_class.call('[]')).to be_empty
    end

    it 'drops nil' do
      expect(described_class.call(nil)).to be_empty
    end

    it 'drops a blank string' do
      expect(described_class.call('   ')).to be_empty
    end

    it 'drops free text carrying no year' do
      expect(described_class.call('n.d.', 'undated')).to be_empty
    end

    it 'reads a three-digit year' do
      expect(described_class.call('113')).to eq [113]
    end

    it 'drops a two-digit year whose century is unknowable' do
      expect(described_class.call('81')).to be_empty
    end

    it 'drops EDTF unspecified digits' do
      expect(described_class.call('19XX', '196X')).to be_empty
    end

    it 'keeps the parsable values when only some parse' do
      expect(described_class.call('[]', '1905', nil)).to eq [1905]
    end

    it 'reads a Date object' do
      expect(described_class.call(Date.new(1954, 1, 14))).to eq [1954]
    end
  end

  describe '.call with EDTF intervals' do
    it 'contributes every year an interval spans' do
      expect(described_class.call('1940/1943')).to eq [1940, 1941, 1942, 1943]
    end

    it 'ignores the approximation qualifier' do
      expect(described_class.call('1940~/1942')).to eq [1940, 1941, 1942]
    end

    it 'takes the one readable endpoint of an open interval' do
      expect(described_class.call('1940/..')).to eq [1940]
    end

    it 'orders the endpoints so a reversed interval still expands' do
      expect(described_class.call('1943/1940')).to eq [1940, 1941, 1942, 1943]
    end

    it 'collapses an interval whose endpoints are the same year' do
      expect(described_class.call('1940-01/1940-12')).to eq [1940]
    end

    it 'truncates rather than rejecting an implausibly wide interval' do
      years = described_class.call('0000/9999')

      expect(years.length).to eq described_class::MAX_INTERVAL_SPAN
    end
  end

  describe '.call with common non-EDTF forms' do
    it 'spans a hyphenated year range' do
      expect(described_class.call('1940-1943')).to eq [1940, 1941, 1942, 1943]
    end

    it 'spans a hyphenated year range with spaces' do
      expect(described_class.call('1940 - 1942')).to eq [1940, 1941, 1942]
    end

    it 'still reads an ISO year-month as one year, not a range' do
      expect(described_class.call('1962-11', '1962-11-05')).to eq [1962]
    end

    it 'reads every year in a comma-separated list' do
      expect(described_class.call('1860, 1861, 1864')).to eq [1860, 1861, 1864]
    end

    it 'reads each part of a semicolon-separated list' do
      expect(described_class.call('1940-1942; 1950')).to eq [1940, 1941, 1942, 1950]
    end

    it 'reads past a circa prefix' do
      expect(described_class.call('ca. 1967', 'Circa 1956', 'c. 1900')).to eq [1900, 1956, 1967]
    end
  end

  describe '.call with EDTF sets' do
    it 'reads every member of a one-of set' do
      expect(described_class.call('[1667,1668,1670..1672]')).to eq [1667, 1668, 1670, 1671, 1672]
    end

    it 'reads every member of an all-of set' do
      expect(described_class.call('{1960,1961}')).to eq [1960, 1961]
    end

    it 'keeps the readable endpoint of an open run in a set' do
      expect(described_class.call('[..1760]', '{1985..}')).to eq [1760, 1985]
    end
  end

  describe '.call with catalog decade forms' do
    it 'drops a decade written with a trailing hyphen, bracketed or not' do
      expect(described_class.call('[192-?]', 'ca. 197-', '199-')).to be_empty
    end

    it 'still reads a three-digit year that opens a range' do
      expect(described_class.call('950-1050')).to eq [950]
    end
  end
end
