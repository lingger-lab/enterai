class AddUserAndPaymentRefToReservations < ActiveRecord::Migration[8.0]
  # nullable로 추가 — 기존 토큰 모드 예약 호환 유지
  def change
    add_reference :reservations, :user, null: true, foreign_key: true,
                  comment: "회원 가입한 사용자 (null이면 비회원 토큰 모드)"
  end
end
