class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.references :reservation, null: false, foreign_key: true
      t.integer :rating
      t.text :content
      t.string :author_name
      t.string :category
      t.boolean :is_published, null: false, default: false
      t.string :access_token, null: false

      t.timestamps
    end

    add_index :reviews, :access_token, unique: true
    add_index :reviews, :is_published
    remove_index :reviews, :reservation_id
    add_index :reviews, :reservation_id, unique: true
  end
end
