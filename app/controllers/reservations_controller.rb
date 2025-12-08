class ReservationsController < ApplicationController
  def new
    @reservation = Reservation.new
  end
  
  def create
    @reservation = Reservation.new(reservation_params)
    
    if @reservation.save
      # Turbo Stream을 사용한 애니메이션 처리
      respond_to do |format|
        format.html { redirect_to reservation_path(@reservation), notice: "예약이 완료되었습니다!" }
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
    @reservation = Reservation.find(params[:id])
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
      selected_subjects: []
    )
  end
end

