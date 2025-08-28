class RemoveAnalyticsReportingFromAccountSettings < ActiveRecord::Migration[6.1]
  def up
    # Remove analytics_reporting from all existing accounts and ensure analytics is set
    Account.find_each do |account|
      if account.settings&.key?('analytics_reporting')
        # If analytics_reporting was enabled, ensure analytics is also enabled
        if ActiveModel::Type::Boolean.new.cast(account.settings['analytics_reporting']) && !ActiveModel::Type::Boolean.new.cast(account.settings['analytics'])
          account.settings['analytics'] = '1'
        end
        
        # Remove the old analytics_reporting setting
        account.settings.delete('analytics_reporting')
        account.save!
      end
    end
  end

  def down
    # This migration cannot be safely reversed as it removes data
    # If needed, you would need to recreate the analytics_reporting setting
    # based on the current analytics setting
  end
end
