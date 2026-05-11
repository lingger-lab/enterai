# 수강생 마이페이지 (스캐폴드)
#
# 모드:
# - 토큰 모드 (default): 이메일 + 연락처 뒷자리 입력으로 조회 (기존 lookup과 통합)
# - 회원 모드 (AUTH_PROVIDER=kakao/email): 로그인 사용자 마이페이지
class AccountController < ApplicationController
  def show
    # 회원 모드 — 로그인 사용자
    if FeatureFlags.auth_provider != "token" && user_signed_in?
      @user = current_user
      @reservations = @user.reservations.includes(:time_slot, :review).order(reservation_datetime: :desc)
      render :show
      return
    end

    # 토큰 모드 — 기존 lookup으로 리다이렉트
    redirect_to lookup_reservations_path
  end

  private

  # Devise 미연결 시 nil 반환 (안전장치)
  def user_signed_in?
    respond_to?(:current_user) && current_user.present?
  rescue
    false
  end

  def current_user
    nil
  end
end
