class HomeController < ApplicationController
  def index
    @reviews = Review.published.submitted.where.not(content: [nil, ""]).order(created_at: :desc).limit(6)
  end

  def privacy_policy
    # 개인정보 처리방침 페이지
  end
end

