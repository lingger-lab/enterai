class Review < ApplicationRecord
  CATEGORIES = %w[직장인 시니어 소상공인].freeze

  belongs_to :reservation

  validates :rating, inclusion: { in: 1..5 }, allow_nil: true
  validates :content, length: { maximum: 2000 }
  validates :author_name, length: { maximum: 50 }
  validates :category, inclusion: { in: CATEGORIES }, allow_blank: true
  validates :reservation_id, uniqueness: true

  scope :published, -> { where(is_published: true) }
  scope :submitted, -> { where.not(rating: nil).where.not(content: [nil, ""]) }
  scope :by_category, ->(cat) { where(category: cat) }

  before_create :generate_access_token

  def submitted?
    rating.present? && content.present?
  end

  private

  def generate_access_token
    self.access_token ||= SecureRandom.urlsafe_base64(32)
  end
end
