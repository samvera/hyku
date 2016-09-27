config = YAML.load(ERB.new(IO.read(Rails.root + 'config' + 'redis.yml')).result)[Rails.env].with_indifferent_access
require 'redis'
Redis.current = begin
                  Redis.new(config.except(:sentinel).merge(thread_safe: true, sentinels: [(config[:sentinel] if config[:sentinel] && config[:sentinel][:host])]))
                rescue
                  nil
                end
