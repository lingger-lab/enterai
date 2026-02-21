class EmailNotificationJob < ApplicationJob
  queue_as :default

  def perform(reservation_id, notification_type = "created")
    reservation = Reservation.find(reservation_id)

    case notification_type
    when "created"
      ReservationMailer.reservation_created(reservation).deliver_now
    when "confirmed"
      ReservationMailer.reservation_confirmed(reservation).deliver_now
    when "cancelled"
      ReservationMailer.reservation_cancelled(reservation).deliver_now
    when "schedule_changed"
      ReservationMailer.schedule_changed(reservation).deliver_now
    when "reminder"
      ReservationMailer.reminder(reservation).deliver_now
    end
  rescue => e
    Rails.logger.error "이메일 발송 실패 (#{notification_type}): #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end
end
