# frozen_string_literal: true

module ActiveJobTenant
  extend ActiveSupport::Concern

  included do
    attr_accessor :tenant

    attr_writer :current_account
  end

  module ClassMethods
    def deserialize(job_data)
      super.tap do |job|
        job.tenant = job_data['tenant']
        job.current_account = nil
      end
    end

    def non_tenant_job?
      @non_tenant_job
    end

    def non_tenant_job
      @non_tenant_job = true
    end

    def find_job_with_in_redis(queue:, klass:, tenant_id:)
      queue.find do |job|
        if tenant_id.present?
          job.args.first['job_class'] == klass.to_s && job.args.first['tenant'] == tenant_id
        else
          job.args.first['job_class'] == klass.to_s
        end
      end
    end

    def find_job(klass:, tenant_id: nil, queue_name: :default)
      queue = ENV.fetch('HYRAX_ACTIVE_JOB_QUEUE', 'sidekiq')
      if queue == 'sidekiq'
        result = find_job_with_in_redis(queue: Sidekiq::Queue.new(queue_name), klass: klass.name, tenant_id: tenant_id)
        result ||= find_job_with_in_redis(queue: Sidekiq::ScheduledSet.new, klass: klass.name, tenant_id: tenant_id)
        result || find_job_with_in_redis(queue: Sidekiq::RetrySet.new, klass: klass.name, tenant_id: tenant_id)
      elsif queue == 'good_job'
        if tenant_id.present?
          GoodJob::Job.where("finished_at is null and serialized_params->>'tenant' = ? and serialized_params->>'job_class' = ?", tenant_id, klass.name).any?
        else
          GoodJob::Job.where("finished_at is null and serialized_params->>'job_class' = ?", klass.name).any?
        end
      else
        Rails.logger.error("Job engine #{queue} does not support recurring jobs")
      end
    end
  end

  def serialize
    super.merge('tenant' => Apartment::Tenant.current)
  end

  def perform_now
    if non_tenant_job?
      super
    else
      switch do
        super
      end
    end
  end

  private

  delegate :non_tenant_job?, to: :class

  def current_account
    @current_account ||= Account.find_by(tenant: current_tenant)
  end

  def current_tenant
    tenant || Apartment::Tenant.current
  end

  def switch
    Apartment::Tenant.switch(current_tenant) do
      yield
    end
  end
end
