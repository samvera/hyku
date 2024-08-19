class AddFieldsToCounterMetric < ActiveRecord::Migration[6.1]
  def change
    add_column :hyrax_counter_metrics, :title, :string unless column_exists?(:hyrax_counter_metrics, :title)
    add_column :hyrax_counter_metrics, :year_of_publication, :integer, index: true unless column_exists?(:hyrax_counter_metrics, :year_of_publication)
    add_column :hyrax_counter_metrics, :publisher, :string, index: true unless column_exists?(:hyrax_counter_metrics, :publisher)
    add_column :hyrax_counter_metrics, :author, :string, index: true unless column_exists?(:hyrax_counter_metrics, :author)
  end
end
