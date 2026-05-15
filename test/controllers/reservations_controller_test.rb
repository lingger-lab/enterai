require "test_helper"

class ReservationsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  def valid_params(overrides = {})
    {
      name: "테스터",
      phone: "010-9876-5432",
      email: "tester@example.com",
      reservation_datetime: 3.days.from_now,
      coaching_type: "온라인 코칭",
      privacy_agreed: "1",
      package: "starter",
      service_type: "coaching"
    }.merge(overrides)
  end

  test "GET /reservations/new — 코칭 폼 정상 응답" do
    get new_reservation_path
    assert_response :success
    assert_match(/예약/, @response.body)
  end

  test "GET /reservations/new?service_type=app_development&package=basic" do
    get new_reservation_path(service_type: "app_development", package: "basic")
    assert_response :success
  end

  test "POST /reservations — 코칭 예약 성공 시 redirect" do
    assert_difference -> { Reservation.count }, 1 do
      post reservations_path, params: { reservation: valid_params }
    end
    assert_response :redirect
    res = Reservation.last
    assert_equal "테스터", res.name
    assert_equal "pending", res.status
  end

  test "POST /reservations — 앱 개발 예약 성공 (coaching_type 없이)" do
    assert_difference -> { Reservation.count }, 1 do
      post reservations_path, params: {
        reservation: valid_params(
          service_type: "app_development",
          package: "basic",
          coaching_type: nil
        )
      }
    end
    assert_response :redirect
    res = Reservation.last
    assert_nil res.coaching_type
    assert_equal "basic", res.package
  end

  test "POST /reservations — 필수 필드 누락 시 422" do
    assert_no_difference -> { Reservation.count } do
      post reservations_path, params: { reservation: valid_params(name: "") }
    end
    assert_response :unprocessable_entity
  end

  test "POST /reservations — 동의 미체크 시 422" do
    assert_no_difference -> { Reservation.count } do
      post reservations_path, params: { reservation: valid_params(privacy_agreed: "0") }
    end
    assert_response :unprocessable_entity
  end

  test "GET /reservations/:id — 토큰 정확하면 200" do
    perform_enqueued_jobs do
      # 알림 잡은 즉시 실행하지 않도록 분리
    end
    res = Reservation.create!(valid_params.merge(privacy_agreed: true))
    get reservation_path(res, token: res.access_token)
    assert_response :success
  end

  test "GET /reservations/:id — 토큰 잘못되면 redirect" do
    res = Reservation.create!(valid_params.merge(privacy_agreed: true))
    get reservation_path(res, token: "wrong_token")
    assert_response :redirect
  end

  test "GET /reservations/lookup — 조회 폼 응답" do
    get lookup_reservations_path
    assert_response :success
  end

  test "POST /reservations/lookup — 잘못된 입력 시 안내" do
    post lookup_reservations_path, params: { email: "", phone_last4: "" }
    assert_response :success
    assert_match(/입력해주세요/, @response.body)
  end

  test "PATCH /reservations/:id/cancel — 토큰 정확하면 취소" do
    res = Reservation.create!(valid_params.merge(privacy_agreed: true))
    patch cancel_reservation_path(res, token: res.access_token)
    assert_response :redirect
    assert_equal "cancelled", res.reload.status
  end

  test "PATCH /reservations/:id/cancel — 토큰 잘못되면 취소 안 됨" do
    res = Reservation.create!(valid_params.merge(privacy_agreed: true))
    patch cancel_reservation_path(res, token: "wrong")
    assert_response :redirect
    assert_equal "pending", res.reload.status
  end

  test "GET /reservations/available_dates — JSON 배열 응답" do
    get available_dates_reservations_path, params: { month: Date.current.to_s }
    assert_response :success
    assert_equal "application/json", @response.media_type
    body = JSON.parse(@response.body)
    assert_kind_of Array, body
  end

  test "GET /reservations/available_slots — JSON 배열 응답" do
    get available_slots_reservations_path, params: { date: Date.current.to_s }
    assert_response :success
    body = JSON.parse(@response.body)
    assert_kind_of Array, body
  end

  test "예약 생성 시 SMS/Email/Kakao 알림 잡이 enqueue됨" do
    assert_enqueued_jobs 3, only: [SmsNotificationJob, EmailNotificationJob, KakaoNotificationJob] do
      post reservations_path, params: { reservation: valid_params }
    end
  end

  test "POST /reservations — 슬롯 예약 성공 시 슬롯이 booked로 변경" do
    slot = TimeSlot.create!(
      date: 3.days.from_now.to_date,
      start_time: "14:00",
      end_time: "15:00",
      coaching_type: "온라인 코칭",
      status: "available"
    )

    assert_difference -> { Reservation.count }, 1 do
      post reservations_path, params: {
        reservation: valid_params(time_slot_id: slot.id)
      }
    end
    assert_response :redirect
    assert_equal "booked", slot.reload.status
  end

  test "POST /reservations — 이미 booked인 슬롯은 예약 실패" do
    slot = TimeSlot.create!(
      date: 3.days.from_now.to_date,
      start_time: "15:00",
      end_time: "16:00",
      coaching_type: "온라인 코칭",
      status: "booked"
    )

    assert_no_difference -> { Reservation.count } do
      post reservations_path, params: {
        reservation: valid_params(time_slot_id: slot.id)
      }
    end
    assert_response :unprocessable_entity
    assert_match(/이미 예약/, @response.body)
  end

  test "POST /reservations — 과거 시간으로 예약 시 422" do
    assert_no_difference -> { Reservation.count } do
      post reservations_path, params: {
        reservation: valid_params(reservation_datetime: 1.hour.ago)
      }
    end
    assert_response :unprocessable_entity
  end
end
