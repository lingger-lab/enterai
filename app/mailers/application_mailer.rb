class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("SENDGRID_FROM_EMAIL", "noreply@enter.ai")
  
  # SendGrid는 SMTP를 통해 설정됨 (config/initializers/sendgrid.rb 참조)
end

