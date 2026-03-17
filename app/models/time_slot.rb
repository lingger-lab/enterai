class TimeSlot < ApplicationRecord
  STATUSES = %w[available booked blocked].freeze

  has_one :reservation

  validates :date, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :coaching_type, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :date, uniqueness: { scope: [:start_time, :coaching_type], message: "같은 시간대에 이미 슬롯이 존재합니다" }
  validate :end_after_start

  scope :available, -> { where(status: "available") }
  scope :on_date, ->(date) { where(date: date) }
  scope :future, -> { where("date >= ?", Date.current) }
  scope :for_coaching_type, ->(type) { where(coaching_type: type) }

  def available?
    status == "available"
  end

  def booked?
    status == "booked"
  end

  def book!
    update!(status: "booked")
  end

  def release!
    update!(status: "available")
  end

  def time_range_label
    st = start_time.respond_to?(:strftime) ? start_time.strftime("%H:%M") : start_time.to_s[0..4]
    et = end_time.respond_to?(:strftime) ? end_time.strftime("%H:%M") : end_time.to_s[0..4]
    "#{st} - #{et}"
  end

  def self.bulk_create(start_date:, end_date:, weekdays:, start_hour:, end_hour:, interval_minutes:, coaching_type:)
    slots = []
    now = Time.current

    (start_date..end_date).each do |date|
      next unless weekdays.include?(date.wday)

      current_minutes = start_hour * 60
      end_minutes = end_hour * 60

      while current_minutes + interval_minutes <= end_minutes
        h1 = current_minutes / 60
        m1 = current_minutes % 60
        h2 = (current_minutes + interval_minutes) / 60
        m2 = (current_minutes + interval_minutes) % 60
        slot_start = format("%02d:%02d", h1, m1)
        slot_end = format("%02d:%02d", h2, m2)

        slots << {
          date: date,
          start_time: slot_start,
          end_time: slot_end,
          coaching_type: coaching_type,
          status: "available",
          created_at: now,
          updated_at: now
        }

        current_minutes += interval_minutes
      end
    end

    return 0 if slots.empty?
    insert_all(slots, unique_by: :idx_time_slots_unique).count
  end

  private

  def end_after_start
    return unless end_time.present? && start_time.present?
    errors.add(:end_time, "종료 시간은 시작 시간 이후여야 합니다") if end_time <= start_time
  end
end
