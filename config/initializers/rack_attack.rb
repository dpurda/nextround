class Rack::Attack
  throttle("claims/ip", limit: 10, period: 1.minute) do |request|
    request.ip if request.path == "/claim" && request.post?
  end
end
