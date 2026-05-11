# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_05_11_042334) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "reservation_id", null: false
    t.integer "amount", null: false, comment: "결제 금액 (원)"
    t.string "status", default: "pending", null: false, comment: "pending/issued/paid/failed/refunded/partially_refunded"
    t.string "pg_provider", comment: "toss, kakaopay, naverpay 등"
    t.string "pg_payment_key", comment: "PG가 발급한 결제 고유 ID"
    t.string "pg_order_id", comment: "회사가 발급한 주문 ID"
    t.string "pg_method", comment: "카드/계좌이체/간편결제 등"
    t.text "pg_raw_response", comment: "PG 응답 원본 (디버그용)"
    t.datetime "issued_at", comment: "결제링크 발송 시각"
    t.datetime "paid_at", comment: "결제 완료 시각"
    t.datetime "refunded_at", comment: "환불 완료 시각"
    t.integer "refunded_amount", default: 0, comment: "환불 금액"
    t.text "memo", comment: "관리자 메모"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["paid_at"], name: "index_payments_on_paid_at"
    t.index ["pg_order_id"], name: "index_payments_on_pg_order_id", unique: true, where: "(pg_order_id IS NOT NULL)"
    t.index ["pg_payment_key"], name: "index_payments_on_pg_payment_key", unique: true, where: "(pg_payment_key IS NOT NULL)"
    t.index ["reservation_id"], name: "index_payments_on_reservation_id"
    t.index ["status"], name: "index_payments_on_status"
  end

  create_table "reservations", force: :cascade do |t|
    t.datetime "reservation_datetime", null: false, comment: "예약 날짜/시간"
    t.string "coaching_type", comment: "코칭 형태"
    t.string "selected_subjects", default: [], comment: "선택 과목", array: true
    t.text "requests", comment: "요청사항"
    t.boolean "privacy_agreed", default: false, null: false, comment: "개인정보 동의"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "encrypted_name", comment: "암호화된 이름 (attr_encrypted)"
    t.string "encrypted_name_iv", comment: "이름 암호화 IV (attr_encrypted)"
    t.text "encrypted_phone", comment: "암호화된 연락처 (attr_encrypted)"
    t.string "encrypted_phone_iv", comment: "연락처 암호화 IV (attr_encrypted)"
    t.text "encrypted_email", comment: "암호화된 이메일 (attr_encrypted)"
    t.string "encrypted_email_iv", comment: "이메일 암호화 IV (attr_encrypted)"
    t.string "status", default: "pending", null: false, comment: "예약 상태"
    t.string "reminder_job_id"
    t.string "package", default: "standard", null: false, comment: "선택 패키지"
    t.string "access_token"
    t.bigint "time_slot_id"
    t.string "service_type", default: "coaching"
    t.bigint "user_id", comment: "회원 가입한 사용자 (null이면 비회원 토큰 모드)"
    t.index ["access_token"], name: "index_reservations_on_access_token", unique: true
    t.index ["package"], name: "index_reservations_on_package"
    t.index ["reservation_datetime"], name: "index_reservations_on_reservation_datetime"
    t.index ["status"], name: "index_reservations_on_status"
    t.index ["time_slot_id"], name: "index_reservations_on_time_slot_id"
    t.index ["user_id"], name: "index_reservations_on_user_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "reservation_id", null: false
    t.integer "rating"
    t.text "content"
    t.string "author_name"
    t.string "category"
    t.boolean "is_published", default: false, null: false
    t.string "access_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_token"], name: "index_reviews_on_access_token", unique: true
    t.index ["is_published"], name: "index_reviews_on_is_published"
    t.index ["reservation_id"], name: "index_reviews_on_reservation_id", unique: true
  end

  create_table "settings", force: :cascade do |t|
    t.string "key", null: false, comment: "설정 키 (예: business_hours, response_sla)"
    t.text "value", comment: "설정 값"
    t.string "category", default: "general", comment: "카테고리 (general/business/legal/notification)"
    t.text "description", comment: "관리자용 설명"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_settings_on_category"
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "time_slots", force: :cascade do |t|
    t.date "date", null: false
    t.time "start_time", null: false
    t.time "end_time", null: false
    t.string "coaching_type", null: false
    t.string "status", default: "available", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date", "start_time", "coaching_type"], name: "idx_time_slots_unique", unique: true
    t.index ["date", "status"], name: "idx_time_slots_date_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "provider", comment: "kakao, google 등 (null이면 이메일 가입)"
    t.string "uid", comment: "OAuth provider의 user id"
    t.text "encrypted_name"
    t.string "encrypted_name_iv"
    t.text "encrypted_phone"
    t.string "encrypted_phone_iv"
    t.boolean "marketing_agreed", default: false, comment: "마케팅 정보 수신 동의 (정보통신망법 §50)"
    t.datetime "marketing_agreed_at"
    t.datetime "last_sign_in_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true, where: "(provider IS NOT NULL)"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "payments", "reservations"
  add_foreign_key "reservations", "time_slots"
  add_foreign_key "reservations", "users"
  add_foreign_key "reviews", "reservations"
end
