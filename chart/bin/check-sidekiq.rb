# Run this via rails runner
require "socket"

hostname = Socket.gethostname
if Sidekiq::ProcessSet.new.any? { |ps| ps["hostname"] == hostname }
  exit 0
else
  exit 1
end
