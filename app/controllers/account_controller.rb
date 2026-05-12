# 수강생 마이페이지
class AccountController < ApplicationController
  def show
    if user_signed_in?
      @user = current_user
      @reservations = Reservation.where(user_id: @user.id).or(
        Reservation.where(email_lookup_match(@user.email))
      ).includes(:time_slot, :review).order(reservation_datetime: :desc)
      render :show
    else
      # 비로그인 사용자: 로그인 페이지로 (또는 토큰 lookup)
      redirect_to new_user_session_path, notice: "로그인 후 이용 가능합니다."
    end
  end

  private

  # 회원 이메일로 예약 조회 시 매칭 (Reservation.email은 암호화되어 raw 비교 불가, 향후 회원-예약 자동 연결 시 user_id로 대체)
  def email_lookup_match(email)
    # placeholder — user_id가 채워진 후엔 사용 안 함
    { id: -1 }
  end
end
