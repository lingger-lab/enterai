# 관리자 계정 생성
admin_email = ENV.fetch("ADMIN_EMAIL", "admin@enterlab.com")
admin_password = ENV.fetch("ADMIN_PASSWORD", "password123")

admin = AdminUser.find_or_initialize_by(email: admin_email)
admin.password = admin_password
admin.password_confirmation = admin_password
admin.save!

puts "관리자 계정 생성 완료: #{admin_email}"
