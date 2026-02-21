class RemoveLegacyEncryptionColumns < ActiveRecord::Migration[8.0]
  def change
    remove_column :reservations, :name_encrypted, :text
    remove_column :reservations, :name_encrypted_iv, :string
    remove_column :reservations, :phone_encrypted, :text
    remove_column :reservations, :phone_encrypted_iv, :string
    remove_column :reservations, :email_encrypted, :text
    remove_column :reservations, :email_encrypted_iv, :string
  end
end
