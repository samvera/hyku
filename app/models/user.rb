# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class User < ApplicationRecord
  has_one :user_batch_email, dependent: :destroy

  # Includes lib/rolify from the rolify gem
  rolify
  # Connects this user object to Hydra behaviors.
  include Hydra::User
  # Connects this user object to Hyrax behaviors.
  include Hyrax::User
  include Hyrax::UserUsageStats

  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise(*Hyku::Application.user_devise_parameters)

  after_create :add_default_group_membership!
  after_update :mark_all_undelivered_messages_as_delivered!, if: -> { batch_email_frequency == 'never' }

  # set default scope to exclude guest users
  default_scope -> { where(guest: false) }

  scope :for_repository, lambda {
    joins(:roles)
  }

  scope :registered, -> { for_repository.group(:id).where(guest: false) }

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/PerceivedComplexity
  def self.from_omniauth(auth)
    u = find_by(provider: auth.provider, uid: auth.uid)
    return u if u

    u = find_by(email: auth&.info&.email&.downcase)
    u ||= new
    u.provider = auth.provider
    u.uid = auth.uid
    u.email = auth&.info&.email
    u.email ||= auth.uid
    # rubocop:disable Performance/RedundantMatch
    u.email = [auth.uid, '@', Site.instance.account.email_domain].join unless u.email.match?('@')
    # rubocop:enable Performance/RedundantMatch

    # Passwords are required for all records, but in the case of OmniAuth,
    # we're relying on the other auth provider.  Hence we're creating a random
    # password.
    u.password = Devise.friendly_token[0, 20] if u.new_record?

    # assuming the user model has a name
    u.display_name = auth&.info&.name
    u.display_name ||= "#{auth&.info&.first_name} #{auth&.info&.last_name}" if auth&.info&.first_name && auth&.info&.last_name
    u.save
    u
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/PerceivedComplexity

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier.
  def to_s
    email
  end

  def admin?
    has_role?(:admin) || has_role?(:admin, Site.instance)
  end

  # Favor admin? over is_admin? but provided for backwards compatability.
  alias is_admin? admin?

  def superadmin?
    has_role? :superadmin
  end

  # Favor admin? over is_admin? but provided for backwards compatability.
  alias is_superadmin? superadmin?

  # This comes from a checkbox in the proprietor interface
  # Rails checkboxes are often nil or "0" so we handle that
  # case directly
  def superadmin=(value)
    value = ActiveModel::Type::Boolean.new.cast(value)
    if value
      add_role :superadmin
    else
      remove_role :superadmin
    end
  end

  def site_roles
    roles.site
  end

  def site_roles=(roles)
    roles.reject!(&:blank?)

    existing_roles = site_roles.pluck(:name)
    new_roles = roles - existing_roles
    removed_roles = existing_roles - roles

    new_roles.each do |r|
      add_role r, Site.instance
    end

    removed_roles.each do |r|
      remove_role r, Site.instance
    end
  end

  # Hyrax::Group memberships are tracked through User#roles. This method looks up
  # the Hyrax::Groups the user is a member of and returns each one in an Array.
  # Example:
  #   u = User.last
  #   u.roles
  #   => #<ActiveRecord::Associations::CollectionProxy [#<Role id: 8, name: "member",
  #      resource_type: "Hyrax::Group", resource_id: 2,...>]>
  #   u.hyrax_groups
  #   => [#<Hyrax::Group id: 2, name: "registered", description: nil,...>]
  def hyrax_groups
    # Why compact?  In theory we shouldn't need this.  But in tests we're seeing a case
    roles.where(name: 'member', resource_type: 'Hyrax::Group').map(&:resource).uniq.compact
  end

  # Override method from hydra-access-controls v11.0.0 to use Hyrax::Groups.
  # NOTE: DO NOT RENAME THIS METHOD - it is required for permissions to function properly.
  # @return [Array] Hyrax::Group names the User is a member of
  def groups
    hyrax_groups.map(&:name)
  rescue NoMethodError
    # Not quite raising the same exception, but this code is here to catch a flakey spec.  What we're
    # seeing is that an element in `hyrax_groups` is `nil` and which does not respond to `#name`.
    # Looking at `#hyrax_groups` method, it's unclear how we'd find `nil`.
    #
    # Perhaps the `Hyrax::Group` is in a tenant and `Role` is not?  Hmm.
    raise "Hyrax::Groups: #{roles.where(name: 'member', resource_type: 'Hyrax::Group').all.inspect}\nRoles: #{roles.all.inspect}"
  end

  # NOTE: This is an alias for #groups to clarify what the method is doing.
  # This is necessary because #groups overrides a method from a gem.
  # @return [Array] Hyrax::Group names the User is a member of
  def hyrax_group_names
    groups
  end

  # TODO: this needs tests and to be moved to the service
  # Tmp shim to handle bug
  def group_roles
    hyrax_groups.map(&:roles).flatten.uniq
  end

  # TODO: The current way this method works may be problematic; if a User signs up
  # in the global tenant, they won't get group memberships for any tenant. Need to
  # identify all the places this kind of situation can arise (invited users, etc)
  # and decide what to do about it.
  def add_default_group_membership!
    return if guest?
    return if Account.global_tenant?

    Hyrax::Group.find_or_create_by!(name: Ability.registered_group_name).add_members_by_id(id)
  end

  # When the user sets their batch email frequency to 'never' then we want to mark all the messages
  # (really the receipts of the messages) to is_delivered tru
  def mark_all_undelivered_messages_as_delivered!
    mailbox.receipts.where(is_delivered: false).find_each do |receipt|
      receipt.update(is_delivered: true)
    end
  end

  # Returns hash summary of user statistics for a date range... uses the prior month by default
  def statistics_for(start_date: (Time.zone.now - 1.month).beginning_of_month, end_date: (Time.zone.now - 1.month).end_of_month)
    stats_period = start_date..end_date
    last_month_stats = stats.where(date: stats_period)

    return nil if last_month_stats.empty?

    {
      new_file_downloads: last_month_stats.sum(:file_downloads),
      new_work_views: last_month_stats.sum(:work_views),
      total_file_views:,
      total_file_downloads:,
      total_work_views:
    }
  end

  def last_emailed_at
    UserBatchEmail.find_or_create_by(user: self).last_emailed_at
  end

  def last_emailed_at=(value)
    UserBatchEmail.find_or_create_by(user: self).update(last_emailed_at:  value)
  end
end
# rubocop:enable Metrics/ClassLength
