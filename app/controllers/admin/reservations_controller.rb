class Admin::ReservationsController < Admin::BaseController
  before_action :set_reservation, only: [:show, :edit, :update, :update_status, :send_sms]

  def index
    status_counts = Reservation.group(:status).count
    @stats = {
      total: status_counts.values.sum,
      pending: status_counts.fetch("pending", 0),
      confirmed: status_counts.fetch("confirmed", 0),
      cancelled: status_counts.fetch("cancelled", 0),
      completed: status_counts.fetch("completed", 0),
      today: Reservation.where(reservation_datetime: Date.today.all_day).count,
      this_week: Reservation.where(created_at: 1.week.ago..).count
    }

    reservations = Reservation.order(created_at: :desc)
    reservations = reservations.where(status: params[:status]) if params[:status].present?
    @pagy, @reservations = pagy(reservations)
  end

  def show
  end

  def edit
  end

  def update
    if @reservation.update(reservation_params)
      # 일정이 변경된 경우 SMS + 이메일 발송
      if @reservation.saved_change_to_reservation_datetime?
        SmsNotificationJob.perform_later(@reservation.id, "schedule_changed")
        EmailNotificationJob.perform_later(@reservation.id, "schedule_changed")
      end
      redirect_to admin_reservation_path(@reservation), notice: "예약이 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update_status
    old_status = @reservation.status
    new_status = params[:status]

    if @reservation.can_transition_to?(new_status) && @reservation.update(status: new_status)
      # 상태 변경 SMS + 이메일 발송
      if old_status != new_status
        SmsNotificationJob.perform_later(@reservation.id, new_status)
        EmailNotificationJob.perform_later(@reservation.id, new_status)
      end

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to admin_reservation_path(@reservation), notice: "상태가 변경되었습니다." }
      end
    else
      redirect_to admin_reservation_path(@reservation), alert: "상태 변경에 실패했습니다."
    end
  end

  def send_sms
    SmsNotificationJob.perform_later(@reservation.id, "manual")
    redirect_to admin_reservation_path(@reservation), notice: "SMS가 발송되었습니다."
  end

  private

  def set_reservation
    @reservation = Reservation.find(params[:id])
  end

  def reservation_params
    params.require(:reservation).permit(:reservation_datetime, :coaching_type, :status, :requests, :package, selected_subjects: [])
  end
end
