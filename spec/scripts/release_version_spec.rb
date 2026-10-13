# frozen_string_literal: true

require 'spec_helper'
require_relative '../../.github/scripts/release_version'

RSpec.describe ReleaseVersion do
  describe '.next' do
    it 'increments only the RC sequence for an active staging release candidate' do
      expect(described_class.next(current: '7.2.0.rc1', resolved: '7.2.1', staging: true)).to eq('7.2.0.rc2')
    end
  end

  describe '.next' do
    it 'starts a new staging release candidate sequence at rc1 after a stable release' do
      expect(described_class.next(current: '7.2.0', resolved: '7.2.1', staging: true)).to eq('7.2.1.rc1')
    end
  end

  describe '.next' do
    it 'removes the RC suffix when promoting a release candidate to production' do
      expect(described_class.next(current: '7.2.0.rc2', resolved: '7.2.1', staging: false)).to eq('7.2.0')
    end
  end
end
