class ReservationMailer < ApplicationMailer
  def reservation_created(reservation)
    @reservation = reservation
    @datetime = format_datetime(reservation.reservation_datetime)
    @contact = ENV.fetch("CONTACT_PHONE", "0502-1927-1910")
    mail(to: reservation.email, subject: "[EnterLab] 예약이 완료되었습니다")
  end

  def reservation_confirmed(reservation)
    @reservation = reservation
    @datetime = format_datetime(reservation.reservation_datetime)
    @contact = ENV.fetch("CONTACT_PHONE", "0502-1927-1910")
    mail(to: reservation.email, subject: "[EnterLab] 예약이 확정되었습니다")
  end

  def reservation_cancelled(reservation)
    @reservation = reservation
    @datetime = format_datetime(reservation.reservation_datetime)
    @contact = ENV.fetch("CONTACT_PHONE", "0502-1927-1910")
    mail(to: reservation.email, subject: "[EnterLab] 예약이 취소되었습니다")
  end

  def schedule_changed(reservation)
    @reservation = reservation
    @datetime = format_datetime(reservation.reservation_datetime)
    @contact = ENV.fetch("CONTACT_PHONE", "0502-1927-1910")
    mail(to: reservation.email, subject: "[EnterLab] 예약 일정이 변경되었습니다")
  end

  def reminder(reservation)
    @reservation = reservation
    @datetime = format_datetime(reservation.reservation_datetime)
    @contact = ENV.fetch("CONTACT_PHONE", "0502-1927-1910")
    mail(to: reservation.email, subject: "[EnterLab] 내일 예약이 있습니다")
  end

  def review_request(reservation)
    @reservation = reservation
    @review = reservation.review
    @review_url = write_review_url(token: @review.access_token)
    @datetime = format_datetime(reservation.reservation_datetime)
    mail(to: reservation.email, subject: "[EnterLab] 코칭은 어떠셨나요? 후기를 남겨주세요")
  end

  def admin_notification(reservation)
    @reservation = reservation
    admin_email = ENV.fetch("ADMIN_EMAIL") { raise "ADMIN_EMAIL must be set" }
    mail(to: admin_email, subject: "[EnterLab] 새로운 예약이 접수되었습니다 - #{reservation.name}")
  end

  private

  def format_datetime(datetime)
    datetime.strftime("%Y년 %m월 %d일 %H시 %M분")
  end
end
