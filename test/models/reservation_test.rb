require "test_helper"

class ReservationTest < ActiveSupport::TestCase
  def valid_attrs(overrides = {})
    {
      name: "홍길동",
      phone: "010-1234-5678",
      email: "test@example.com",
      reservation_datetime: 3.days.from_now,
      coaching_type: "온라인 코칭",
      privacy_agreed: true,
      package: "starter",
      service_type: "coaching"
    }.merge(overrides)
  end

  test "필수 필드 모두 있으면 유효함" do
    res = Reservation.new(valid_attrs)
    assert res.valid?, res.errors.full_messages.to_sentence
  end

  test "이름 누락 시 무효" do
    res = Reservation.new(valid_attrs(name: nil))
    refute res.valid?
    assert res.errors[:name].present?
  end

  test "이메일 형식 오류 시 무효" do
    res = Reservation.new(valid_attrs(email: "not-an-email"))
    refute res.valid?
  end

  test "전화번호 형식 오류 시 무효" do
    res = Reservation.new(valid_attrs(phone: "abc"))
    refute res.valid?
  end

  test "개인정보 동의 누락 시 무효" do
    res = Reservation.new(valid_attrs(privacy_agreed: false))
    refute res.valid?
    assert res.errors[:privacy_agreed].present?
  end

  test "유효하지 않은 패키지는 무효" do
    res = Reservation.new(valid_attrs(package: "invalid_pkg"))
    refute res.valid?
  end

  test "PACKAGES 모든 키는 유효" do
    Reservation::PACKAGES.keys.each do |pkg|
      res = Reservation.new(valid_attrs(package: pkg))
      assert res.valid?, "#{pkg} 무효: #{res.errors.full_messages}"
    end
  end

  test "APP_DEV_PACKAGES도 유효 (service_type=app_development)" do
    Reservation::APP_DEV_PACKAGES.keys.each do |pkg|
      res = Reservation.new(valid_attrs(
        package: pkg,
        service_type: "app_development",
        coaching_type: nil
      ))
      assert res.valid?, "#{pkg} 무효: #{res.errors.full_messages}"
    end
  end

  test "app_development 서비스는 coaching_type 필수 아님" do
    res = Reservation.new(valid_attrs(
      service_type: "app_development",
      package: "basic",
      coaching_type: nil
    ))
    assert res.valid?
  end

  test "coaching 서비스는 coaching_type 필수" do
    res = Reservation.new(valid_attrs(coaching_type: nil))
    refute res.valid?
  end

  test "코칭 형태가 정의 외이면 무효" do
    res = Reservation.new(valid_attrs(coaching_type: "비공식 코칭"))
    refute res.valid?
  end

  test "선택 과목은 선택사항이며 정의된 옵션만 허용" do
    res = Reservation.new(valid_attrs(selected_subjects: ["AI 기초 이해"]))
    assert res.valid?

    res2 = Reservation.new(valid_attrs(selected_subjects: ["존재하지 않는 과목"]))
    refute res2.valid?
  end

  test "저장 시 PII 필드는 평문 컬럼에 저장되지 않음" do
    res = Reservation.create!(valid_attrs(name: "암호테스트", email: "secret@example.com"))
    raw = Reservation.connection.execute("SELECT encrypted_name, encrypted_email FROM reservations WHERE id = #{res.id}").first
    refute_equal "암호테스트", raw["encrypted_name"]
    refute_equal "secret@example.com", raw["encrypted_email"]
    assert_equal "암호테스트", res.reload.name
    assert_equal "secret@example.com", res.reload.email
  end

  test "access_token이 자동 생성됨" do
    res = Reservation.create!(valid_attrs)
    assert res.access_token.present?
    assert_operator res.access_token.length, :>=, 30
  end

  test "초기 상태는 pending" do
    res = Reservation.create!(valid_attrs)
    assert_equal "pending", res.status
  end

  test "pending → confirmed 전환 가능" do
    res = Reservation.create!(valid_attrs)
    assert res.can_transition_to?("confirmed")
    assert res.can_transition_to?("cancelled")
  end

  test "completed → 다른 상태 전환 불가" do
    res = Reservation.create!(valid_attrs(status: "completed"))
    refute res.can_transition_to?("confirmed")
    refute res.can_transition_to?("cancelled")
  end

  test "cancelled → 다른 상태 전환 불가 (cancelled는 종착)" do
    res = Reservation.create!(valid_attrs(status: "cancelled"))
    refute res.can_transition_to?("pending"), "cancelled → pending 차단 (슬롯 이중예약 위험)"
    refute res.can_transition_to?("confirmed")
    refute res.can_transition_to?("completed")
  end

  test "과거 시간으로 예약 생성 불가" do
    res = Reservation.new(valid_attrs(reservation_datetime: 1.hour.ago))
    refute res.valid?
    assert res.errors[:reservation_datetime].present?
  end

  test "미래 시간으로 예약 생성 가능" do
    res = Reservation.new(valid_attrs(reservation_datetime: 1.hour.from_now))
    assert res.valid?, res.errors.full_messages.to_sentence
  end

  test "package_label은 패키지명을 반환" do
    res = Reservation.new(valid_attrs(package: "standard"))
    assert_equal "STANDARD", res.package_label
  end
end
