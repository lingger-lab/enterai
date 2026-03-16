class ReservationsController < ApplicationController
  def new
    @reservation = Reservation.new
    @reservation.package = params[:package] if params[:package].present? && Reservation::PACKAGES.key?(params[:package])
  end
  
  def create
    @reservation = Reservation.new(reservation_params)

    if @reservation.save
      respond_to do |format|
        format.html { redirect_to reservation_path(@reservation, token: @reservation.access_token), notice: "예약이 완료되었습니다!" }
        format.turbo_stream
      end
    else
      # 에러 발생 시 폼 다시 표시
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end
  
  def show
    @reservation = Reservation.find_by(id: params[:id])
    unless @reservation && @reservation.access_token.present? && ActiveSupport::SecurityUtils.secure_compare(@reservation.access_token, params[:token].to_s)
      redirect_to root_path, alert: "접근 권한이 없습니다."
    end
  end
  
  private
  
  def reservation_params
    params.require(:reservation).permit(
      :name,
      :phone,
      :email,
      :reservation_datetime,
      :coaching_type,
      :requests,
      :privacy_agreed,
      :package,
      selected_subjects: []
    )
  end
end

