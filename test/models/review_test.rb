require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  def valid_reservation
    Reservation.create!(
      name: "리뷰테스터",
      phone: "010-1111-2222",
      email: "review@example.com",
      reservation_datetime: 3.days.from_now,
      coaching_type: "온라인 코칭",
      privacy_agreed: true,
      package: "starter",
      service_type: "coaching"
    )
  end

  test "예약과 1:1 관계로 생성됨" do
    res = valid_reservation
    review = Review.create!(reservation: res)
    assert_equal res.id, review.reservation_id
  end

  test "동일 예약에 두 번째 후기 생성 불가" do
    res = valid_reservation
    Review.create!(reservation: res)
    duplicate = Review.new(reservation: res)
    refute duplicate.valid?
  end

  test "rating은 1~5 범위만 허용" do
    res = valid_reservation
    review = Review.new(reservation: res, rating: 6)
    refute review.valid?
  end

  test "category는 정의된 값만 허용" do
    res = valid_reservation
    review = Review.new(reservation: res, category: "유효하지않음")
    refute review.valid?

    valid_review = Review.new(reservation: res, category: "직장인")
    assert valid_review.valid?
  end

  test "access_token 자동 생성" do
    res = valid_reservation
    review = Review.create!(reservation: res)
    assert review.access_token.present?
    assert_operator review.access_token.length, :>=, 30
  end

  test "submitted? — rating + content 둘 다 있어야 true" do
    res = valid_reservation
    review = Review.create!(reservation: res)
    refute review.submitted?

    review.update(rating: 5)
    refute review.submitted?

    review.update(content: "좋았습니다")
    assert review.submitted?
  end

  test "submitted scope — content 빈 문자열도 제외" do
    res1 = valid_reservation
    Review.create!(reservation: res1, rating: 5, content: "")

    res2 = Reservation.create!(valid_reservation.attributes.except("id", "created_at", "updated_at", "access_token", "encrypted_name", "encrypted_name_iv", "encrypted_phone", "encrypted_phone_iv", "encrypted_email", "encrypted_email_iv").merge("reservation_datetime" => 5.days.from_now))
    res2.update!(name: "다른사람", phone: "010-3333-4444", email: "other@example.com", privacy_agreed: true)
    Review.create!(reservation: res2, rating: 4, content: "유효 후기")

    assert_equal 1, Review.submitted.count
  end

  test "published scope — is_published true만 반환" do
    res = valid_reservation
    Review.create!(reservation: res, rating: 5, content: "공개", is_published: true)
    assert_equal 1, Review.published.count
  end
end
