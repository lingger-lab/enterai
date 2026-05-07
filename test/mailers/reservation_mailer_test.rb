require "test_helper"

class ReservationMailerTest < ActionMailer::TestCase
  setup do
    @reservation = Reservation.create!(
      name: "메일러테스터",
      phone: "010-9999-0000",
      email: "mailer@example.com",
      reservation_datetime: 3.days.from_now,
      coaching_type: "온라인 코칭",
      privacy_agreed: true,
      package: "standard",
      service_type: "coaching"
    )
  end

  test "reservation_created 메일 — 수신자/제목 검증" do
    mail = ReservationMailer.reservation_created(@reservation)
    assert_equal [@reservation.email], mail.to
    assert mail.subject.present?
  end

  test "admin_notification 메일 — 관리자 수신" do
    mail = ReservationMailer.admin_notification(@reservation)
    assert mail.to.present?
    assert mail.subject.present?
  end

  test "reservation_confirmed 메일 — 확정 알림" do
    mail = ReservationMailer.reservation_confirmed(@reservation)
    assert_equal [@reservation.email], mail.to
    assert mail.subject.present?
  end

  test "reservation_cancelled 메일 — 취소 알림" do
    mail = ReservationMailer.reservation_cancelled(@reservation)
    assert_equal [@reservation.email], mail.to
    assert mail.subject.present?
  end
end
