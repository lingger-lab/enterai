class CreateSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :settings do |t|
      t.string :key, null: false, comment: "설정 키 (예: business_hours, response_sla)"
      t.text :value, comment: "설정 값"
      t.string :category, default: "general", comment: "카테고리 (general/business/legal/notification)"
      t.text :description, comment: "관리자용 설명"

      t.timestamps
    end

    add_index :settings, :key, unique: true
    add_index :settings, :category
  end
end
