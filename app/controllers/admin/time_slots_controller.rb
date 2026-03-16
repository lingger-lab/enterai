class Admin::TimeSlotsController < Admin::BaseController
  before_action :set_time_slot, only: [:destroy, :toggle_block]

  def index
    @month = params[:month] ? Date.parse(params[:month]) : Date.current
    @range = @month.beginning_of_month..@month.end_of_month

    slots = TimeSlot.where(date: @range).order(:date, :start_time)
    slots = slots.where(coaching_type: params[:coaching_type]) if params[:coaching_type].present?

    @slots_by_date = slots.group_by(&:date)
    @stats = {
      total: slots.count,
      available: slots.where(status: "available").count,
      booked: slots.where(status: "booked").count,
      blocked: slots.where(status: "blocked").count
    }
  end

  def new
    @time_slot = TimeSlot.new
  end

  def create
    @time_slot = TimeSlot.new(time_slot_params)

    if @time_slot.save
      redirect_to admin_time_slots_path(month: @time_slot.date.strftime("%Y-%m")), notice: "슬롯이 생성되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def bulk_new
  end

  def bulk_create
    start_date = Date.parse(params[:start_date]) rescue nil
    end_date = Date.parse(params[:end_date]) rescue nil

    unless start_date && end_date && end_date >= start_date
      flash[:alert] = "유효한 날짜를 입력해주세요."
      render :bulk_new, status: :unprocessable_entity and return
    end
    weekdays = Array(params[:weekdays]).map(&:to_i)
    start_hour = params[:start_hour].to_i
    end_hour = params[:end_hour].to_i
    interval = params[:interval_minutes].to_i
    coaching_type = params[:coaching_type]

    unless Reservation::COACHING_TYPES.include?(coaching_type)
      flash[:alert] = "유효하지 않은 코칭 형태입니다."
      render :bulk_new, status: :unprocessable_entity and return
    end

    if weekdays.empty? || interval <= 0 || start_hour >= end_hour || (end_date - start_date).to_i > 90
      flash[:alert] = "입력값을 확인해주세요. (최대 90일 범위)"
      render :bulk_new, status: :unprocessable_entity and return
    end

    count = TimeSlot.bulk_create(
      start_date: start_date,
      end_date: end_date,
      weekdays: weekdays,
      start_hour: start_hour,
      end_hour: end_hour,
      interval_minutes: interval,
      coaching_type: coaching_type
    )

    redirect_to admin_time_slots_path(month: start_date.strftime("%Y-%m")), notice: "#{count}개 슬롯이 생성되었습니다."
  rescue => e
    flash[:alert] = "생성 실패: #{e.message}"
    render :bulk_new, status: :unprocessable_entity
  end

  def destroy
    if @time_slot.booked?
      redirect_to admin_time_slots_path, alert: "예약된 슬롯은 삭제할 수 없습니다."
    else
      @time_slot.destroy
      redirect_to admin_time_slots_path, notice: "슬롯이 삭제되었습니다."
    end
  end

  def toggle_block
    if @time_slot.booked?
      redirect_to admin_time_slots_path, alert: "예약된 슬롯은 차단할 수 없습니다."
    elsif @time_slot.available?
      @time_slot.update!(status: "blocked")
      redirect_to admin_time_slots_path, notice: "슬롯이 차단되었습니다."
    else
      @time_slot.update!(status: "available")
      redirect_to admin_time_slots_path, notice: "슬롯이 활성화되었습니다."
    end
  end

  private

  def set_time_slot
    @time_slot = TimeSlot.find(params[:id])
  end

  def time_slot_params
    params.require(:time_slot).permit(:date, :start_time, :end_time, :coaching_type)
  end
end
