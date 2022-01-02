class AddDataCiteToAccount < ActiveRecord::Migration[5.2]
  def change
    unless column_exists?(:accounts, :data_cite_endpoint_id)
      add_reference :accounts, :data_cite_endpoint, index: true
    end
  end
end
