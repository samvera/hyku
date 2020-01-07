namespace :sidekiq do
  desc "Health check for sidekiq worker process."
  task status: [:environment] do
    require "socket"

    hostname = Socket.gethostname
    if Sidekiq::ProcessSet.new.any? { |ps| ps["hostname"] == hostname }
      exit 0
    else
      exit 1
    end
  end
end
