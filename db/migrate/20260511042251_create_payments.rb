class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.references :reservation, null: false, foreign_key: true
      t.integer :amount, null: false, comment: "결제 금액 (원)"
      t.string :status, null: false, default: "pending",
                        comment: "pending/issued/paid/failed/refunded/partially_refunded"
      t.string :pg_provider, comment: "toss, kakaopay, naverpay 등"
      t.string :pg_payment_key, comment: "PG가 발급한 결제 고유 ID"
      t.string :pg_order_id, comment: "회사가 발급한 주문 ID"
      t.string :pg_method, comment: "카드/계좌이체/간편결제 등"
      t.text :pg_raw_response, comment: "PG 응답 원본 (디버그용)"
      t.datetime :issued_at, comment: "결제링크 발송 시각"
      t.datetime :paid_at, comment: "결제 완료 시각"
      t.datetime :refunded_at, comment: "환불 완료 시각"
      t.integer :refunded_amount, default: 0, comment: "환불 금액"
      t.text :memo, comment: "관리자 메모"

      t.timestamps
    end

    add_index :payments, :status
    add_index :payments, :pg_payment_key, unique: true, where: "pg_payment_key IS NOT NULL"
    add_index :payments, :pg_order_id, unique: true, where: "pg_order_id IS NOT NULL"
    add_index :payments, :paid_at
  end
end
