class Goal < ApplicationRecord
  belongs_to :user

  has_many :subgoals, -> { ordered }, dependent: :destroy, inverse_of: :goal
  has_many :quests, through: :subgoals
  has_many :small_rewards, dependent: :destroy, inverse_of: :goal

  validates :user_id, uniqueness: true
  validates :value_statement, presence: true
  validates :title, presence: true

  scope :ordered, -> { order(created_at: :asc, id: :asc) }
end
