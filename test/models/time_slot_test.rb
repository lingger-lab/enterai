require "test_helper"

class TimeSlotTest < ActiveSupport::TestCase
  def valid_attrs(overrides = {})
    {
      date: 3.days.from_now.to_date,
      start_time: "10:00",
      end_time: "11:00",
      coaching_type: "온라인 코칭",
      status: "available"
    }.merge(overrides)
  end

  test "유효한 슬롯은 저장됨" do
    slot = TimeSlot.new(valid_attrs)
    assert slot.valid?
  end

  test "end_time이 start_time보다 이전이면 무효" do
    slot = TimeSlot.new(valid_attrs(start_time: "11:00", end_time: "10:00"))
    refute slot.valid?
  end

  test "필수 필드 누락 시 무효" do
    refute TimeSlot.new(valid_attrs(date: nil)).valid?
    refute TimeSlot.new(valid_attrs(start_time: nil)).valid?
    refute TimeSlot.new(valid_attrs(end_time: nil)).valid?
    refute TimeSlot.new(valid_attrs(coaching_type: nil)).valid?
  end

  test "available scope" do
    a = TimeSlot.create!(valid_attrs)
    TimeSlot.create!(valid_attrs(start_time: "12:00", end_time: "13:00", status: "booked"))
    assert_includes TimeSlot.available, a
    assert_equal 1, TimeSlot.available.count
  end

  test "future scope" do
    future = TimeSlot.create!(valid_attrs)
    assert_includes TimeSlot.future, future
  end

  test "book! 호출 시 status가 booked로 변경" do
    slot = TimeSlot.create!(valid_attrs)
    slot.book!
    assert slot.reload.booked?
  end

  test "release! 호출 시 status가 available로 복귀" do
    slot = TimeSlot.create!(valid_attrs(status: "booked"))
    slot.release!
    assert slot.reload.available?
  end

  test "동일 시간대 + 코칭 타입 중복 슬롯 생성 불가" do
    TimeSlot.create!(valid_attrs)
    duplicate = TimeSlot.new(valid_attrs)
    refute duplicate.valid?
  end

  test "bulk_create — 평일만 생성" do
    start_date = Date.parse("2026-06-01") # 월
    end_date = Date.parse("2026-06-07")   # 일
    weekdays = [1, 2, 3, 4, 5] # 평일

    count = TimeSlot.bulk_create(
      start_date: start_date,
      end_date: end_date,
      weekdays: weekdays,
      start_hour: 10,
      end_hour: 12,
      interval_minutes: 60,
      coaching_type: "출장 코칭"
    )

    # 평일 5일 × 2시간/일(60분 슬롯 2개) = 10
    assert_equal 10, count
  end

  test "time_range_label 형식" do
    slot = TimeSlot.new(valid_attrs)
    assert_match(/\d{2}:\d{2} - \d{2}:\d{2}/, slot.time_range_label)
  end
end
