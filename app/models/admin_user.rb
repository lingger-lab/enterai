class AdminUser < ApplicationRecord
  devise :database_authenticatable, :rememberable, :validatable, :lockable
end
