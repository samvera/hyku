# frozen_string_literal: true

class RemoveGoodJobActiveIdIndex < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    reversible do |dir|
      dir.up do
        remove_index :good_jobs, name: :index_good_jobs_on_active_job_id if connection.index_name_exists?(:good_jobs, :index_good_jobs_on_active_job_id)
      end

      dir.down do
        add_index :good_jobs, :active_job_id, name: :index_good_jobs_on_active_job_id unless connection.index_name_exists?(:good_jobs, :index_good_jobs_on_active_job_id)
      end
    end
  end
end
