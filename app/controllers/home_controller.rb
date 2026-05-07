class HomeController < ApplicationController
  def index
    @reviews = Review.published.submitted.includes(:reservation).order(created_at: :desc).limit(6)
  end

  def privacy_policy
    # 개인정보 처리방침 페이지
  end

  def terms
    # 이용약관
  end

  def refund_policy
    # 환불 정책
  end

  def faq
    # 자주 묻는 질문
  end
end

