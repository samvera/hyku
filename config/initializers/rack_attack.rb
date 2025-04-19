# No more that 20 requersts per minitue per ip
Rack::Attack.throttle("requests by ip", limit: 20, period: 60) do |request|
  request.ip
end
