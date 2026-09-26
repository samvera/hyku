# frozen_string_literal: true

module ReleaseVersion
  RC_VERSION = /\A(?<base>\d+\.\d+\.\d+)\.rc(?<number>\d+)\z/

  def self.next(current:, resolved:, staging:)
    return resolved unless staging

    current_rc = RC_VERSION.match(current)
    return "#{current_rc[:base]}.rc#{current_rc[:number].to_i + 1}" if current_rc

    "#{resolved}.rc1"
  end
end

if $PROGRAM_NAME == __FILE__
  current, resolved, staging = ARGV
  abort 'usage: release_version.rb CURRENT RESOLVED_VERSION STAGING' unless current && resolved && staging

  puts ReleaseVersion.next(current: current, resolved: resolved, staging: staging == 'true')
end
