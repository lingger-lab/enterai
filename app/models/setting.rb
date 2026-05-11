# 운영 설정 키-값 저장소
# 사용: Setting.get("business_hours"), Setting.set("business_hours", "평일 10:00~18:00")
# 관리자 페이지(/admin/settings)에서 편집 가능
class Setting < ApplicationRecord
  CATEGORIES = %w[general business legal notification].freeze

  validates :key, presence: true, uniqueness: true
  validates :category, inclusion: { in: CATEGORIES }

  # 기본값 — Setting 레코드 없을 때 폴백
  DEFAULTS = {
    "business_hours" => "평일 10:00 ~ 18:00 (토/일/공휴일 휴무)",
    "response_sla" => "영업일 24시간 내 답변",
    "commerce_reg_no" => "", # 통신판매업 신고번호 (예: 제2026-경남김해-0123호)
    "vat_included" => "false", # true/false 문자열
    "kakao_channel_url" => "" # 카카오 채널 URL
  }.freeze

  # 빠른 조회 (캐싱 가능, 테이블 없으면 DEFAULTS 폴백)
  def self.get(key)
    record = find_by(key: key)
    record&.value.presence || DEFAULTS[key.to_s] || ""
  rescue ActiveRecord::StatementInvalid
    # 마이그레이션 미적용 시 안전장치
    DEFAULTS[key.to_s] || ""
  end

  def self.set(key, value)
    record = find_or_initialize_by(key: key)
    record.value = value
    record.save!
    record
  end

  def self.bool(key)
    %w[true 1 yes y].include?(get(key).to_s.downcase)
  end

  def self.all_with_defaults
    DEFAULTS.map do |key, default|
      record = find_by(key: key)
      {
        key: key,
        value: record&.value || default,
        is_default: record.nil?,
        category: record&.category || "general",
        description: record&.description
      }
    end
  end
end
