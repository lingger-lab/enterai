require "test_helper"

class EmailNotificationJobTest < ActiveJob::TestCase
  setup do
    @reservation = Reservation.create!(
      name: "이메일잡",
      phone: "010-7777-8888",
      email: "email_job@example.com",
      reservation_datetime: 3.days.from_now,
      coaching_type: "온라인 코칭",
      privacy_agreed: true,
      package: "starter",
      service_type: "coaching"
    )
  end

  test "Email 잡이 큐에 enqueue됨" do
    assert_enqueued_with(job: EmailNotificationJob) do
      EmailNotificationJob.perform_later(@reservation.id, "created")
    end
  end

  test "SENDGRID_API_KEY 미설정 시 잡이 silently skip" do
    # test 환경엔 SENDGRID_API_KEY 없음 → 로그만 남기고 종료
    original_key = ENV["SENDGRID_API_KEY"]
    ENV["SENDGRID_API_KEY"] = nil
    assert_nothing_raised do
      EmailNotificationJob.perform_now(@reservation.id, "created")
    end
  ensure
    ENV["SENDGRID_API_KEY"] = original_key
  end
end
