class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "notifications:1"
  end
end
