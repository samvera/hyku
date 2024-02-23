# frozen_string_literal: true

# WorkAuthorization models users granted access to groups of works. The instigator of the authorizations is
# outside the model.  In the case of PALNI/PALCI there will be a Shibboleth/SAML authentication that
# indicates we should create a WorkAuthorization entry for a group of works.
#
# @note Transactions across data storage layers (e.g. postgres and fedora) are precarious.  Fedora
#       doesn't have proper transactions and there is not a clear concept of Postgres and Fedora
#       sharing a transaction pool.  However, we can emulate one by having a postgres transaction that:
#       first does all of the postgres and then does one (ideally single) fedora change.  It is
#       not bullet proof but does hopefully improve the chances of data integrity.
#
# @see https://github.com/scientist-softserv/palni-palci/issues/633
class WorkAuthorization < ActiveRecord::Base # rubocop:disable ApplicationRecord
  class WorkNotFoundError < StandardError
    def initialize(user:, work:)
      "Unable to authorize #{user.class} #{user.user_key.inspect} for work with ID=#{work.id} because work does not exist."
    end
  end

  class GroupNotFoundError < StandardError
    def initialize(user:, group:)
      "Unable to authorize #{user.class} #{user.user_key.inspect} for group with name=#{group.name.inspect} because group does not exist."
    end
  end

  belongs_to :user

  # This will be a non-ActiveRecord resource
  validates :work_pid, presence: true

  ##
  # When a :user signs in, we want to re-authorize the works' groups that are part of their latest
  # authentication.  We want to de-authorize access to any works' groups that are not part of their recent
  # authentication.
  #
  # @param user [User]
  # @param authorize_until [Time] authorize the given work_pid(s) until this point in time.
  # @param revoke_expirations_before [Time] expire all authorizations that have expires_at less than or equal to this parameter.
  # @param work_pid [String, Array<String>]
  # @param scope [String] the OpenID scope string that might include additional works to authorize.
  #
  # @see OmniAuth::Strategies::OpenIDConnectDecorator
  # @see .extract_pids_from
  # rubocop:disable Rails/FindBy
  def self.handle_signin_for!(user:, authorize_until: 1.day.from_now, work_pid: nil, scope: nil, revoke_expirations_before: Time.zone.now)
    Rails.logger.info("#{self.class}.#{__method__} granting authorization to work_pid: #{work_pid.inspect} and scope: #{scope.inspect}.")

    pids = Array.wrap(work_pid) + extract_pids_from(scope: scope)

    # Maybe we get multiple pids; let's handle that accordingly
    pids.each do |pid|
      begin
        work = ActiveFedora::Base.where(id: pid).first
        group = Hyrax::Group.find_by(name: pid)
        authorize!(user: user, work: work, group: group, expires_at: authorize_until)
      rescue WorkNotFoundError, GroupNotFoundError
        Rails.logger.info("Unable to find work_pid of #{pid.inspect}.")
      end
    end

    # We re-authorized the above pids, so it should not be in this query.
    where("user_id = :user_id AND expires_at <= :expires_at", user_id: user.id, expires_at: revoke_expirations_before).pluck(:work_pid).each do |pid|
      work = ActiveFedora::Base.where(id: pid).first
      revoke!(user: user, work: work)
    end
  end
  # rubocop:enable Rails/FindBy

  ##
  # A regular expression that identifies the :work_pid for Hyrax work.
  #
  # @see .extract_pids_from
  REGEXP_TO_MATCH_PID = %r{/concern/(?<work_type>[^\/]+)/(?<work_pid>[^\?]+)(?<query_param>\?.*)?}

  ##
  # Extract the URL for a CDL object based on the given OAuth scope.
  #
  # @param scope [String]
  # @param request [ActionDispatch::Request, #env, #host_with_port]
  #
  # @return [NilClass] when the scope does not include a work.
  # @return [String] the URL of the provided scope.
  def self.url_from(scope:, request:, with_regexp: REGEXP_TO_MATCH_PID)
    return nil unless scope

    scope.split(/\s+/).map do |scope_element|
      next unless with_regexp.match(scope_element)
      uri = URI.parse(scope_element)
      uri.query = nil
      uri.path += '/manifest'
      scope_element = uri.to_s
      protocol = request.env.fetch('rack.url_scheme', 'https')
      uv_url = protocol + '://' + File.join(request.host_with_port, 'uv/uv.html#?manifest=')
      uv_config_url = protocol + '://' + File.join(request.host_with_port, 'uv/uv-config-reshare.json')
      # rubocop:disable Rails/OutputSafety
      (uv_url + scope_element + '&config=' + uv_config_url).html_safe
      # rubocop:enable Rails/OutputSafety
    end.compact.first
  end

  ##
  # From the given :scope string extract an array of potential work_ids.
  #
  # @param scope [String]
  # @param with_regexp [Regexp]
  #
  # @return [Array<String>] work pid(s) that we found in the given :scope.
  def self.extract_pids_from(scope:, with_regexp: REGEXP_TO_MATCH_PID)
    return [] if scope.blank?

    scope.split(/\s+/).map do |scope_element|
      match = with_regexp.match(scope_element)
      match[:work_pid] if match
    end.compact
  end

  ##
  # Grant the given :user permission to read the work associated with the given :work_pid.
  #
  # @param user [User]
  # @param work [ActiveFedora::Base]
  # @param group [Hyrax::Group]
  #
  # @raise [WorkAuthorization::WorkNotFoundError] when the given :work_pid is not found.
  # @raise [WorkAuthorization::GroupNotFoundError] when the given :group is not found.
  #
  # @see .revoke!
  def self.authorize!(user:, work:, group:, expires_at: 1.day.from_now)
    raise WorkNotFoundError.new(user: user, work: work) unless work
    raise GroupNotFoundError.new(user: user, group: group) unless group

    transaction do
      authorization = find_or_create_by!(user_id: user.id, work_pid: work.id)
      authorization.update!(work_title: work.title, expires_at: expires_at)

      group.add_members_by_id(user.id)
    end
  end

  ##
  # Remove permission for the given :user to read the work associated with the given :work_pid.
  #
  # @param user [User]
  # @param work [ActiveFedora::Base]
  #
  # @see .authorize!
  def self.revoke!(user:, work:)
    return unless work

    # When we delete the authorizations, we want to ensure that we've tidied up the corresponding
    # work's read users.  If for some reason the ActiveFedora save fails, this the destruction of
    # the authorizations will rollback.  Meaning we still have a record of what we've authorized.OB
    transaction do
      where(user_id: user.id, work_pid: work.id).destroy_all
      Rails.logger.info("Looking for a group with name=#{work.id.inspect}.")
      group = Hyrax::Group.find_by(name: work.id)
      return unless group

      group.remove_members_by_id(user.id)
    end
  end

  ##
  # This module is a controller mixin that assumes access to a `session` object.
  #
  # Via {#prepare_for_conditional_work_authorization!} provide the logic for storing a URL to later
  # be available in an authorization request.
  #
  # @example
  #   class ApplicationController < ActionController::Base
  #     include WorkAuthorization::StoreUrlForScope
  #   end
  module StoreUrlForScope
    CDL_SESSION_KEY = 'cdl.requested_work_url'

    ##
    # Responsible for storing in the session the URL that is a candidate for Controlled Digital
    # Lending (CDL) authorization.
    #
    # @param given_url [String,NilClass] when given, favor this URL instead of attempting to find
    #        the stored location.
    # rubocop:disable Style/GuardClause
    def prepare_for_conditional_work_authorization!(given_url = nil)
      if given_url.nil?
        # Note: Accessing `stored_location_for` clears that location from the session; so we need to
        # grab it and then set it again.
        url = stored_location_for(:user)
        store_location_for(:user, url)
      else
        url = given_url
      end

      # If this could be a controlled digital lending (CDL) work, let's not rely on the
      # stored_location (e.g. something that is part of devise and the value being subject to change).
      # Instead, let's set the OmniAuth::Strategies::OpenIDConnectDecorator::CDL_SESSION_KEY key in
      # the session.
      if WorkAuthorization::REGEXP_TO_MATCH_PID.match(url)
        url = request.env['rack.url_scheme'] + '://' + File.join(request.host_with_port, url) if url.start_with?('/')
        Rails.logger.info("=@=@=@=@ Called #{self.class}##{__method__} to set session['#{WorkAuthorization::StoreUrlForScope::CDL_SESSION_KEY}'] to #{url.inspect}.")
        session[WorkAuthorization::StoreUrlForScope::CDL_SESSION_KEY] = url
      end
    end
    # rubocop:enable Style/GuardClause
  end
end
