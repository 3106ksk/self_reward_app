class User < ApplicationRecord
  has_secure_password

  has_one :goal, dependent: :destroy

  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true,
                    length: { maximum: 255 },
                    uniqueness: true
  validates :password, length: { minimum: 8 }, allow_nil: true
end
