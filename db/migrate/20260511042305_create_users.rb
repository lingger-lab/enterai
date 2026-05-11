class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      # Devise: Database Authenticatable
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      # Devise: Recoverable
      t.string :reset_password_token
      t.datetime :reset_password_sent_at

      # Devise: Rememberable
      t.datetime :remember_created_at

      # OmniAuth / 카카오
      t.string :provider, comment: "kakao, google 등 (null이면 이메일 가입)"
      t.string :uid, comment: "OAuth provider의 user id"

      # 프로필 (암호화 — Reservation과 동일 패턴)
      t.text :encrypted_name
      t.string :encrypted_name_iv
      t.text :encrypted_phone
      t.string :encrypted_phone_iv

      # 회원 상태
      t.boolean :marketing_agreed, default: false, comment: "마케팅 정보 수신 동의 (정보통신망법 §50)"
      t.datetime :marketing_agreed_at
      t.datetime :last_sign_in_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, [ :provider, :uid ], unique: true, where: "provider IS NOT NULL"
  end
end
