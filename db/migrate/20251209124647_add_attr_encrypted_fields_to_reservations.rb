class AddAttrEncryptedFieldsToReservations < ActiveRecord::Migration[8.0]
  def change
    # attr_encrypted가 사용하는 기본 칼럼명 형식
    add_column :reservations, :encrypted_name, :text, comment: "암호화된 이름 (attr_encrypted)"
    add_column :reservations, :encrypted_name_iv, :string, comment: "이름 암호화 IV (attr_encrypted)"
    add_column :reservations, :encrypted_phone, :text, comment: "암호화된 연락처 (attr_encrypted)"
    add_column :reservations, :encrypted_phone_iv, :string, comment: "연락처 암호화 IV (attr_encrypted)"
    add_column :reservations, :encrypted_email, :text, comment: "암호화된 이메일 (attr_encrypted)"
    add_column :reservations, :encrypted_email_iv, :string, comment: "이메일 암호화 IV (attr_encrypted)"
  end
end
