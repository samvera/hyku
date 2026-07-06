# frozen_string_literal: true

require 'timeout'

# Resets a public demo ("sandbox") tenant to a stored golden state so that a
# publicly writable demo environment recovers from visitor changes on a
# schedule.
#
# Two operations:
#
# * {#snapshot!} captures the tenant's golden state onto the account: the
#   Site appearance attributes, all content blocks, and the identifiers of
#   featured works. Run it once, after arranging the tenant the way it should
#   look after every reset.
# * {#reset!} destroys visitor-created content (works, file sets, collections,
#   featured entries, Bulkrax importers and exporters), removes visitor
#   created users, restores the snapshot, optionally re-imports a seed corpus
#   through Bulkrax, restores featured works, runs an injectable health check,
#   and stamps the account's last_reset_at on success.
#
# Both operations refuse to run for accounts not flagged public_demo_tenant.
#
# Users are global records in Hyku while role grants live in each tenant
# schema, so "visitor-created users" are identified by their role grants in
# this tenant: any user holding a role here (self-registered users receive a
# registered-group membership role on creation) is swept unless they are a
# superadmin, a tenant superadmin, or on the keep_emails list. Swept users
# lose their role grants in this tenant and are destroyed globally only when
# they hold no roles in any other tenant.
#
# The seed source is deliberately configuration: pass seed_csv_path to
# re-import a corpus through Bulkrax's CSV parser, or omit it to reset to an
# empty-but-branded tenant. The health check is an injectable callable
# receiving the account; wire in whatever validation suits the deployment.
#
# @example
#   account = Account.find_by(cname: 'demo.example.org')
#   DemoTenantResetService.new(account: account).snapshot!
#   DemoTenantResetService.new(
#     account: account,
#     seed_csv_path: '/imports/demo-seed/metadata.csv',
#     keep_emails: ['demoadmin@example.org']
#   ).reset!
#
# rubocop:disable Metrics/ClassLength
class DemoTenantResetService
  class Error < StandardError; end
  class NotDemoTenant < Error; end
  class MissingSnapshot < Error; end
  class ImportFailed < Error; end
  class HealthCheckFailed < Error; end

  # Site columns that must not be restored onto the row.
  SITE_ATTRIBUTE_SKIP = %w[id account_id created_at updated_at].freeze

  # CarrierWave-mounted columns; restored with #update_columns because
  # assigning a filename string through the setter would be treated as a new
  # upload.
  SITE_IMAGE_COLUMNS = %w[banner_image logo_image favicon directory_image
                          default_collection_image default_work_image].freeze

  attr_reader :account, :seed_csv_path, :keep_emails, :import_user_email,
              :health_check, :logger, :import_timeout, :poll_interval

  # @param account [Account] must be flagged public_demo_tenant
  # @param seed_csv_path [String, nil] absolute path to a Bulkrax CSV to re-import; nil skips the import
  # @param keep_emails [Array<String>] user emails that survive the reset in addition to superadmins
  # @param import_user_email [String, nil] owner of the seed import; defaults to the first tenant admin
  # @param health_check [#call, nil] called with the account after restore; a falsey return fails the reset
  # @param logger [Logger]
  # @param import_timeout [Integer] seconds to wait for background jobs to drain after the import
  # @param poll_interval [Integer] seconds between job-queue polls while draining
  # rubocop:disable Metrics/ParameterLists
  def initialize(account:, seed_csv_path: nil, keep_emails: [], import_user_email: nil,
                 health_check: nil, logger: Rails.logger, import_timeout: 3600, poll_interval: 5)
    @account = account
    @seed_csv_path = seed_csv_path
    @keep_emails = Array(keep_emails).map { |email| email.to_s.downcase.strip }.reject(&:empty?)
    @import_user_email = import_user_email
    @health_check = health_check
    @logger = logger
    @import_timeout = import_timeout
    @poll_interval = poll_interval
  end
  # rubocop:enable Metrics/ParameterLists

  # Capture the golden state of the tenant onto the account.
  #
  # @return [Hash] the captured snapshot
  # @raise [NotDemoTenant]
  def snapshot!
    guard_demo_tenant!
    snap = nil
    within_tenant do
      snap = {
        'site' => Site.instance.attributes.except(*SITE_ATTRIBUTE_SKIP),
        'content_blocks' => ContentBlock.all.to_a.to_h { |block| [block.name, block.value] },
        'featured_work_identifiers' => featured_work_identifiers,
        'captured_at' => Time.current.iso8601
      }
    end
    account.update!(demo_tenant_snapshot: snap)
    log "captured golden snapshot (#{snap['content_blocks'].size} content blocks, " \
        "#{snap['featured_work_identifiers'].size} featured works)"
    snap
  end

  # @return [true]
  # @raise [NotDemoTenant, MissingSnapshot, ImportFailed, HealthCheckFailed]
  def reset!
    guard_demo_tenant!
    if account.demo_tenant_snapshot.blank?
      raise MissingSnapshot,
            "No golden snapshot for #{account.cname}; arrange the tenant and run hyku:demo:snapshot first"
    end

    started_at = Time.current
    log 'reset started'
    within_tenant do
      wipe_content!
      remove_visitor_users!
      restore_site!
      restore_content_blocks!
      import_seed! if seed_csv_path.present?
      restore_featured_works!
      run_health_check!
    end
    account.update!(last_reset_at: Time.current)
    log "reset finished in #{(Time.current - started_at).round(1)}s"
    true
  end

  private

  def guard_demo_tenant!
    return if account&.public_demo_tenant?

    raise NotDemoTenant, "#{account&.cname || account.inspect} is not flagged public_demo_tenant; refusing"
  end

  # AccountElevator.switch! (rather than account.switch) is required: it
  # switches the Apartment schema so Valkyrie queries, Site.instance, and
  # Bulkrax's multitenant paths are scoped to the tenant.
  def within_tenant
    previous = Apartment::Tenant.current
    AccountElevator.switch!(account)
    yield
  ensure
    Apartment::Tenant.switch!(previous)
  end

  def wipe_content!
    FeaturedWork.destroy_all
    FeaturedCollection.destroy_all
    content_models.each { |model| destroy_all_of_model(model) }
    Bulkrax::Importer.destroy_all if defined?(Bulkrax::Importer)
    Bulkrax::Exporter.destroy_all if defined?(Bulkrax::Exporter)
    purge_solr_index!
    reindex_admin_sets!
  end

  def content_models
    Hyku::Application.work_types + [Hyrax::FileSet, Hyrax.config.collection_class]
  end

  def destroy_all_of_model(model)
    count = 0
    Hyrax.query_service.find_all_of_model(model:).each do |resource|
      Hyrax.persister.delete(resource:)
      begin
        Hyrax.index_adapter.delete(resource:)
      rescue StandardError
        nil # the full index purge afterwards is the backstop
      end
      count += 1
    rescue StandardError => e
      log("failed to delete #{model} #{resource.id}: #{e.class}: #{e.message}", level: :warn)
    end
    log "removed #{count} #{model} records"
  end

  # Clears index stragglers the model enumeration cannot see (for example
  # records indexed by earlier code paths); admin sets are reindexed after.
  def purge_solr_index!
    Hyrax::SolrService.wipe!
  rescue StandardError => e
    log("solr purge failed: #{e.class}: #{e.message}", level: :warn)
  end

  def reindex_admin_sets!
    ReindexAdminSetsJob.perform_now
  rescue StandardError => e
    log("admin set reindex failed: #{e.class}: #{e.message}", level: :warn)
  end

  def remove_visitor_users!
    User.joins(:roles).distinct.to_a.each do |user|
      next if keep_user?(user)

      strip_tenant_roles!(user)
      destroy_user_unless_active_elsewhere!(user)
    end
  end

  def keep_user?(user)
    user.superadmin? || user.tenant_superadmin? || keep_emails.include?(user.email.to_s.downcase)
  end

  # Removes the users_roles join rows in this tenant's schema; the shared
  # Role records themselves are left in place.
  def strip_tenant_roles!(user)
    user.roles.reload
    user.roles = []
    log "stripped tenant roles from #{user.email}"
  end

  def destroy_user_unless_active_elsewhere!(user)
    return if roles_in_other_tenants?(user)

    user.destroy
    log "destroyed visitor user #{user.email}"
  end

  def roles_in_other_tenants?(user)
    Account.where.not(id: account.id).distinct.pluck(:tenant).any? do |schema|
      Apartment::Tenant.switch(schema) do
        user.roles.reset
        user.roles.exists?
      end
    rescue StandardError
      false
    end
  ensure
    user.roles.reset
  end

  def restore_site!
    attrs = (account.demo_tenant_snapshot['site'] || {})
            .except(*SITE_ATTRIBUTE_SKIP)
            .slice(*Site.column_names)
    return if attrs.blank?

    site = Site.instance
    image_attrs = attrs.slice(*SITE_IMAGE_COLUMNS)
    site.update!(attrs.except(*SITE_IMAGE_COLUMNS))
    site.update_columns(image_attrs) if image_attrs.any? # rubocop:disable Rails/SkipsModelValidations
    log 'restored site appearance attributes'
  end

  def restore_content_blocks!
    blocks = account.demo_tenant_snapshot['content_blocks'] || {}
    blocks.each { |name, value| ContentBlock.update_block(name:, value:) }
    ContentBlock.where.not(name: blocks.keys).destroy_all
    log "restored #{blocks.size} content blocks"
  end

  def import_seed!
    raise ImportFailed, 'Bulkrax is not available in this application' unless defined?(Bulkrax)
    raise ImportFailed, "seed csv not found at #{seed_csv_path}" unless File.exist?(seed_csv_path)

    ensure_default_groups!
    importer = create_importer!
    log "running Bulkrax importer ##{importer.id} for #{seed_csv_path}"
    Bulkrax::ImporterJob.perform_now(importer.id)
    drain_import_jobs!
    verify_import!(importer)
  end

  # Tenants provisioned by some earlier account flows lack the default
  # groups, which breaks admin set lookups during import; creating them is
  # idempotent.
  def ensure_default_groups!
    return unless defined?(Hyrax::Group)

    %w[admin registered public].each { |name| Hyrax::Group.find_or_create_by!(name:) }
  end

  def create_importer!
    Bulkrax::Importer.create!(
      name: "Demo tenant reset #{Time.current.utc.iso8601}",
      admin_set_id: default_admin_set_id,
      user: import_user,
      frequency: 'PT0S',
      parser_klass: 'Bulkrax::CsvParser',
      parser_fields: { 'import_file_path' => seed_csv_path, 'update_files' => false }
    )
  end

  # Reuses the existing admin set rather than triggering creation, which runs
  # workflow grants that fail on partially provisioned tenants.
  def default_admin_set_id
    existing = Hyrax.query_service.find_all_of_model(model: AdminSetResource).first
    (existing&.id || Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id).to_s
  end

  def import_user
    user = User.find_by(email: import_user_email) if import_user_email.present?
    user ||= User.joins(:roles).where(roles: { name: 'admin' }).order(:id).first
    user || raise(ImportFailed, 'no admin user available to own the seed import; pass import_user_email')
  end

  def drain_import_jobs!
    if defined?(GoodJob::Job)
      drain_good_job_queue!
    else
      log('job draining is implemented for GoodJob only; the reset returns before ' \
          'background ingest jobs settle on this queue adapter', level: :warn)
    end
  end

  def drain_good_job_queue!
    Timeout.timeout(import_timeout) do
      wait_for_quiescence!
      # Bulkrax reschedules relationship jobs ten minutes out when a parent
      # is not yet available; pull them forward so collection membership is
      # written before the reset returns.
      loop do
        pulled = pull_relationship_jobs_forward!
        break if pulled.zero?

        log "pulled #{pulled} deferred relationship job(s) forward; re-draining"
        wait_for_quiescence!
      end
    end
  rescue Timeout::Error
    raise ImportFailed, "background jobs did not drain within #{import_timeout}s"
  end

  def wait_for_quiescence!
    stable = 0
    loop do
      if pending_good_jobs.zero?
        stable += 1
        break if stable >= 3
      else
        stable = 0
      end
      sleep poll_interval
    end
  end

  # Only jobs due now: recurring jobs scheduled into the future must not
  # block the drain.
  def pending_good_jobs
    GoodJob::Job.where(finished_at: nil)
                .where('scheduled_at IS NULL OR scheduled_at <= ?', Time.current)
                .count
  end

  def pull_relationship_jobs_forward!
    scope = GoodJob::Job.where(finished_at: nil)
                        .where('scheduled_at > ?', Time.current)
                        .where('job_class ILIKE ?', '%Relationship%')
    count = scope.count
    scope.update_all(scheduled_at: Time.current) if count.positive? # rubocop:disable Rails/SkipsModelValidations
    count
  end

  def verify_import!(importer)
    run = importer.reload.last_run
    raise ImportFailed, "importer ##{importer.id} recorded no run" unless run

    failed = run.failed_records.to_i
    raise ImportFailed, "importer ##{importer.id} failed #{failed} record(s)" if failed.positive?

    log "seed import complete: #{run.processed_records} records processed"
  end

  # Featured works are stored by identifier, not id: a re-imported corpus
  # produces new ids, so restoration matches on the works' import identifier.
  def featured_work_identifiers
    FeaturedWork.order(:order).filter_map do |featured|
      work = find_resource(featured.work_id)
      work && work_identifier(work)
    end
  end

  def find_resource(id)
    Hyrax.query_service.find_by(id:)
  rescue StandardError
    nil
  end

  def work_identifier(work)
    Array(work.try(:bulkrax_identifier)).first || Array(work.try(:source)).first
  end

  def restore_featured_works!
    identifiers = Array(account.demo_tenant_snapshot['featured_work_identifiers']).map(&:to_s)
    return if identifiers.empty?

    FeaturedWork.destroy_all
    index = {}
    Hyku::Application.work_types.each do |model|
      Hyrax.query_service.find_all_of_model(model:).each do |work|
        identifier = work_identifier(work)
        index[identifier.to_s] = work if identifier
      end
    end
    identifiers.each do |identifier|
      work = index[identifier]
      if work
        FeaturedWork.create!(work_id: work.id.to_s)
      else
        log("featured work #{identifier} not found after import", level: :warn)
      end
    end
    log "restored #{FeaturedWork.count} featured works"
  end

  def run_health_check!
    return if health_check.nil?

    result = health_check.call(account)
    raise HealthCheckFailed, "health check returned #{result.inspect} for #{account.cname}" unless result

    log 'health check passed'
  end

  def log(message, level: :info)
    logger.public_send(level, "[DemoTenantReset] #{account.cname}: #{message}")
  end
end
# rubocop:enable Metrics/ClassLength
