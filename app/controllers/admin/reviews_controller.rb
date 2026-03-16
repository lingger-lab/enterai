class Admin::ReviewsController < Admin::BaseController
  before_action :set_review, only: [:toggle_publish]

  def index
    reviews = Review.submitted.includes(:reservation).order(created_at: :desc)
    reviews = reviews.where(is_published: params[:published] == "true") if params[:published].present?
    @pagy, @reviews = pagy(reviews)
  end

  def toggle_publish
    @review.update!(is_published: !@review.is_published)
    redirect_to admin_reviews_path, notice: @review.is_published? ? "후기가 공개되었습니다." : "후기가 비공개되었습니다."
  end

  private

  def set_review
    @review = Review.find(params[:id])
  end
end
