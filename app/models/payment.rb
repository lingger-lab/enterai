class Payment < ApplicationRecord
  STATUSES = %w[pending issued paid failed refunded partially_refunded].freeze
  PG_PROVIDERS = %w[toss kakaopay naverpay nicepay].freeze

  belongs_to :reservation

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }
  validates :pg_provider, inclusion: { in: PG_PROVIDERS }, allow_nil: true
  validates :pg_payment_key, uniqueness: true, allow_nil: true
  validates :pg_order_id, uniqueness: true, allow_nil: true

  scope :paid, -> { where(status: "paid") }
  scope :pending, -> { where(status: "pending") }
  scope :refunded, -> { where(status: %w[refunded partially_refunded]) }

  def paid?
    status == "paid"
  end

  def refundable?
    paid? && refunded_amount < amount
  end

  def mark_paid!(pg_data = {})
    update!(
      status: "paid",
      paid_at: Time.current,
      pg_payment_key: pg_data[:payment_key],
      pg_method: pg_data[:method],
      pg_raw_response: pg_data.to_json
    )
  end

  def mark_failed!(reason = nil)
    update!(
      status: "failed",
      memo: [ memo, reason ].compact.join("\n")
    )
  end
end
