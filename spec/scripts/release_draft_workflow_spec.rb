# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Draft Release Notes workflow' do
  let(:workflow) { File.read(Rails.root.join('.github', 'workflows', 'release-draft.yml')) }

  it 'does not trigger for version-file-only pushes' do
    expect(workflow).to match(/^    paths-ignore:\n      - config\/initializers\/version\.rb$/)
  end

  it 'skips bot-generated version bump commits' do
    expect(workflow).to match(/^  draft:\n(?:    #.*\n)*    if: \$\{\{ !startsWith\(github\.event\.head_commit\.message, 'Bump version to v'\) \}\}$/)
  end

  it 'uses the version-file calculation for the staging draft release' do
    expect(workflow).to include('disable-releaser: true')
    expect(workflow).to include('version: ${{ steps.bump.outputs.version }}')
    expect(workflow).to include('name: v${{ steps.bump.outputs.version }}')
    expect(workflow).to include('tag: v${{ steps.bump.outputs.version }}')
  end
end
