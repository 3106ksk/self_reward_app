class SmallReward < ApplicationRecord
  belongs_to :goal, inverse_of: :small_rewards
  has_many :quests, dependent: :nullify, inverse_of: :small_reward

  validates :title, presence: true
end
