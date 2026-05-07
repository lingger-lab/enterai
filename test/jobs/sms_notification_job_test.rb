require "test_helper"

class SmsNotificationJobTest < ActiveJob::TestCase
  setup do
    @reservation = Reservation.create!(
      name: "잡테스터",
      phone: "010-5555-6666",
      email: "job@example.com",
      reservation_datetime: 3.days.from_now,
      coaching_type: "온라인 코칭",
      privacy_agreed: true,
      package: "starter",
      service_type: "coaching"
    )
  end

  test "SMS 잡이 큐에 enqueue됨" do
    assert_enqueued_with(job: SmsNotificationJob) do
      SmsNotificationJob.perform_later(@reservation.id, "created")
    end
  end

  test "예약이 없으면 RecordNotFound 처리되고 잡은 silently 종료" do
    # 잡 실행해도 예외가 raise되지 않음
    assert_nothing_raised do
      SmsNotificationJob.perform_now(99999, "created")
    end
  end
end
