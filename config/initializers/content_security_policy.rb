# frozen_string_literal: true

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, "https://fonts.gstatic.com", "https://cdn.jsdelivr.net"
    policy.img_src     :self, :data, "https:"
    policy.object_src  :none
    policy.script_src  :self, "https://ga.jspm.io"
    policy.style_src   :self, :unsafe_inline, "https://fonts.googleapis.com", "https://cdn.jsdelivr.net"
    policy.connect_src :self, "https://ga.jspm.io"
    policy.frame_ancestors :none
  end

  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src]
end
