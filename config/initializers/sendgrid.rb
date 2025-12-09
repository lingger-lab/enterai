# SendGrid 설정
if Rails.env.production? || Rails.env.development?
  ActionMailer::Base.smtp_settings = {
    user_name: 'apikey',
    password: ENV.fetch("SENDGRID_API_KEY"),
    domain: ENV.fetch("SENDGRID_DOMAIN", "enterlab.com"),
    address: 'smtp.sendgrid.net',
    port: 587,
    authentication: :plain,
    enable_starttls_auto: true
  }
end

