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

ActiveRecord::Schema[8.0].define(version: 2026_03_16_000004) do
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

  create_table "reservations", force: :cascade do |t|
    t.datetime "reservation_datetime", null: false, comment: "예약 날짜/시간"
    t.string "coaching_type", null: false, comment: "코칭 형태"
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
    t.index ["access_token"], name: "index_reservations_on_access_token", unique: true
    t.index ["package"], name: "index_reservations_on_package"
    t.index ["reservation_datetime"], name: "index_reservations_on_reservation_datetime"
    t.index ["status"], name: "index_reservations_on_status"
  end
end
