class ReservationMailer < ApplicationMailer
  # 사용자에게 예약 확인 이메일 발송
  def confirmation(reservation)
    @reservation = reservation
    mail(
      to: @reservation.email,
      subject: "[Enter.ai] 예약이 완료되었습니다"
    )
  end
  
  # 관리자에게 신규 예약 알림 이메일 발송
  def admin_notification(reservation)
    @reservation = reservation
    admin_email = ENV.fetch("ADMIN_EMAIL", "admin@enter.ai")
    mail(
      to: admin_email,
      subject: "[Enter.ai] 새로운 예약이 접수되었습니다"
    )
  end
end

