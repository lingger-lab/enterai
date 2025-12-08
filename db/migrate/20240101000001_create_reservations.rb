class CreateReservations < ActiveRecord::Migration[8.0]
  def change
    create_table :reservations do |t|
      # 기본 정보
      t.string :name, null: false, comment: "이름"
      t.string :phone, null: false, comment: "연락처"
      t.string :email, null: false, comment: "이메일"
      
      # 예약 정보
      t.datetime :reservation_datetime, null: false, comment: "예약 날짜/시간"
      t.string :coaching_type, null: false, comment: "코칭 형태"
      t.string :selected_subjects, array: true, default: [], comment: "선택 과목"
      t.text :requests, comment: "요청사항"
      
      # 동의 정보
      t.boolean :privacy_agreed, null: false, default: false, comment: "개인정보 동의"
      
      t.timestamps
    end
    
    add_index :reservations, :email
    add_index :reservations, :reservation_datetime
  end
end

