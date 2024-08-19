# frozen_string_literal: true
def db_created?
  ::ActiveRecord::Base.connection_pool.with_connection(&:active?)
rescue
  false
end
