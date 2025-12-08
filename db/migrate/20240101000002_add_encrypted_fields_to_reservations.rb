class AddEncryptedFieldsToReservations < ActiveRecord::Migration[8.0]
  def change
    # attr_encrypted은 암호화된 값과 IV를 별도 컬럼에 저장
    # 기존 필드(name, phone, email)는 그대로 유지하고 암호화 필드 추가
    
    # 이름 암호화 필드
    add_column :reservations, :name_encrypted, :text, comment: "암호화된 이름"
    add_column :reservations, :name_encrypted_iv, :string, comment: "이름 암호화 IV"
    
    # 연락처 암호화 필드
    add_column :reservations, :phone_encrypted, :text, comment: "암호화된 연락처"
    add_column :reservations, :phone_encrypted_iv, :string, comment: "연락처 암호화 IV"
    
    # 이메일 암호화 필드
    add_column :reservations, :email_encrypted, :text, comment: "암호화된 이메일"
    add_column :reservations, :email_encrypted_iv, :string, comment: "이메일 암호화 IV"
    
    # 기존 데이터를 암호화 필드로 마이그레이션
    reversible do |dir|
      dir.up do
        # 기존 데이터가 있다면 암호화 필드로 복사
        # (실제 암호화는 모델의 attr_encrypted가 처리)
        execute <<-SQL
          UPDATE reservations 
          SET name_encrypted = name,
              phone_encrypted = phone,
              email_encrypted = email
          WHERE name_encrypted IS NULL;
        SQL
      end
    end
  end
end

