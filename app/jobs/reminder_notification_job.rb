class ReminderNotificationJob < ApplicationJob
  queue_as :default

  def perform(reservation_id)
    reservation = Reservation.find_by(id: reservation_id)
    return unless reservation
    return if reservation.status.in?(%w[cancelled completed])

    SmsNotificationJob.perform_later(reservation.id, "reminder")
    EmailNotificationJob.perform_later(reservation.id, "reminder")
  rescue => e
    Rails.logger.error "리마인더 발송 실패: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end
end
