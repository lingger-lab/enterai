class ReviewsController < ApplicationController
  def write
    @review = Review.find_by(access_token: params[:token])

    unless @review
      redirect_to root_path, alert: "유효하지 않은 링크입니다."
      return
    end

    if @review.submitted?
      redirect_to review_path(@review, token: @review.access_token), notice: "이미 후기를 작성하셨습니다."
      return
    end

    @reservation = @review.reservation
  end

  def create
    @review = Review.find_by(access_token: params[:review][:access_token])

    unless @review
      redirect_to root_path, alert: "유효하지 않은 요청입니다."
      return
    end

    if @review.submitted?
      redirect_to review_path(@review, token: @review.access_token), alert: "이미 후기를 작성하셨습니다."
      return
    end

    if @review.update(review_params)
      redirect_to review_path(@review, token: @review.access_token), notice: "후기가 등록되었습니다. 감사합니다!"
    else
      @reservation = @review.reservation
      render :write, status: :unprocessable_entity
    end
  end

  def show
    @review = Review.find_by(id: params[:id])
    unless @review && @review.access_token.present? && ActiveSupport::SecurityUtils.secure_compare(@review.access_token, params[:token].to_s)
      redirect_to root_path, alert: "접근 권한이 없습니다."
      return
    end
    @reservation = @review.reservation
  end

  private

  def review_params
    params.require(:review).permit(:rating, :content, :author_name, :category)
  end
end
