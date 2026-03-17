class ReservationsController < ApplicationController
  def new
    @reservation = Reservation.new
    @reservation.package = params[:package] if params[:package].present? && Reservation::PACKAGES.key?(params[:package])
  end

  def create
    @reservation = Reservation.new(reservation_params)

    if @reservation.time_slot_id.present?
      slot = TimeSlot.lock.find_by(id: @reservation.time_slot_id)
      unless slot&.available?
        @reservation.errors.add(:base, "선택한 시간대가 이미 예약되었습니다. 다른 시간을 선택해주세요.")
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.turbo_stream { render :new, status: :unprocessable_entity }
        end
        return
      end
      @reservation.reservation_datetime = slot.date.to_datetime.change(hour: slot.start_time.hour, min: slot.start_time.min)
    end

    if @reservation.save
      respond_to do |format|
        format.html { redirect_to reservation_path(@reservation, token: @reservation.access_token), notice: "예약이 완료되었습니다!" }
        format.turbo_stream
      end
    else
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

  def available_dates
    month = params[:month] ? (Date.parse(params[:month]) rescue Date.current) : Date.current
    range = month.beginning_of_month..month.end_of_month
    dates = TimeSlot.available.future.where(date: range).distinct.pluck(:date).map(&:to_s)
    render json: dates
  end

  def available_slots
    date = Date.parse(params[:date])
    slots = TimeSlot.available.on_date(date).order(:start_time)
    render json: slots.map { |s|
      {
        id: s.id,
        start_time: s.start_time.utc.strftime("%H:%M"),
        end_time: s.end_time.utc.strftime("%H:%M"),
        coaching_type: s.coaching_type
      }
    }
  rescue Date::Error
    render json: []
  end

  def lookup
  end

  def lookup_results
    email = params[:email]&.strip&.downcase
    phone_last4 = params[:phone_last4]&.strip

    if email.blank? || phone_last4.blank? || phone_last4.length != 4
      flash.now[:alert] = "이메일과 연락처 뒷자리 4자리를 입력해주세요."
      render :lookup and return
    end

    @reservations = Reservation.where(status: %w[pending confirmed])
                               .select { |r| r.email&.downcase == email && r.phone&.last(4) == phone_last4 }

    if @reservations.empty?
      flash.now[:alert] = "일치하는 예약을 찾을 수 없습니다."
      render :lookup
    else
      render :lookup_results
    end
  end

  def cancel
    @reservation = Reservation.find_by(id: params[:id])
    token = params[:token]

    unless @reservation && @reservation.access_token.present? && ActiveSupport::SecurityUtils.secure_compare(@reservation.access_token, token.to_s)
      redirect_to lookup_reservations_path, alert: "접근 권한이 없습니다."
      return
    end

    unless @reservation.can_transition_to?("cancelled")
      redirect_to lookup_reservations_path, alert: "이 예약은 취소할 수 없는 상태입니다."
      return
    end

    @reservation.update!(status: "cancelled")
    SmsNotificationJob.perform_later(@reservation.id, "cancelled")
    EmailNotificationJob.perform_later(@reservation.id, "cancelled")
    KakaoNotificationJob.perform_later(@reservation.id, "cancelled")

    redirect_to lookup_reservations_path, notice: "예약이 취소되었습니다."
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
      :time_slot_id,
      selected_subjects: []
    )
  end
end
