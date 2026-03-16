# frozen_string_literal: true

Rack::Attack.throttle("reservations/create/ip", limit: 5, period: 1.hour) do |req|
  req.ip if req.path == "/reservations" && req.post?
end

Rack::Attack.throttle("admin/login/ip", limit: 10, period: 15.minutes) do |req|
  req.ip if req.path.start_with?("/admin/sign_in") && req.post?
end

Rack::Attack.throttle("admin/login/email", limit: 5, period: 15.minutes) do |req|
  if req.path.start_with?("/admin/sign_in") && req.post?
    req.params.dig("admin_user", "email")&.downcase&.strip
  end
end

Rack::Attack.throttle("reservations/lookup/ip", limit: 10, period: 15.minutes) do |req|
  req.ip if req.path == "/reservations/lookup" && req.post?
end

Rack::Attack.throttle("reservations/slots/ip", limit: 30, period: 1.minute) do |req|
  req.ip if req.path.start_with?("/reservations/available")
end

Rack::Attack.throttled_responder = lambda do |_req|
  [429, { "Content-Type" => "text/plain" }, ["요청이 너무 많습니다. 잠시 후 다시 시도해주세요."]]
end
