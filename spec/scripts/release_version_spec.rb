# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../.github/scripts/release_version'

class ReleaseVersionTest < Minitest::Test
  def test_increments_only_the_rc_sequence_for_an_active_staging_release_candidate
    assert_equal '7.2.0.rc2', ReleaseVersion.next(current: '7.2.0.rc1', resolved: '7.2.1', staging: true)
  end

  def test_starts_a_new_staging_release_candidate_sequence_at_rc1_after_a_stable_release
    assert_equal '7.2.1.rc1', ReleaseVersion.next(current: '7.2.0', resolved: '7.2.1', staging: true)
  end

  def test_removes_the_rc_suffix_when_promoting_a_release_candidate_to_production
    assert_equal '7.2.0', ReleaseVersion.next(current: '7.2.0.rc2', resolved: '7.2.1', staging: false)
  end
end
