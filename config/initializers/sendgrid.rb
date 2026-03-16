if ENV['SENDGRID_API_KEY'].present?
  ActionMailer::Base.smtp_settings = {
    address: 'smtp.sendgrid.net',
    port: 587,
    user_name: 'apikey',
    password: ENV['SENDGRID_API_KEY'],
    domain: ENV.fetch('SENDGRID_DOMAIN', 'enterlab.cloud'),
    authentication: :plain,
    enable_starttls_auto: true
  }
end
