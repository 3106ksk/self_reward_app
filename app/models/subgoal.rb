class Subgoal < ApplicationRecord
  MAX_PER_GOAL = 5

  belongs_to :goal, inverse_of: :subgoals
  has_many :quests, -> { ordered }, dependent: :destroy, inverse_of: :subgoal

  validates :title, presence: true
  validates :position, presence: true, numericality: { only_integer: true }
  validate :goal_subgoal_limit, on: :create

  scope :ordered, -> { order(position: :asc, created_at: :asc, id: :asc) }

  def completed?
    quests.loaded? ? quests.any? && quests.all?(&:completed?) : quests.exists? && quests.incomplete.none?
  end

  def reward_available?
    completed? && !reward_claimed?
  end

  def reward_claimed?
    reward_claimed_at.present?
  end

  def reward_label
    reward_title.presence || "休憩ポイント"
  end

  private

  def goal_subgoal_limit
    return unless goal

    if goal.subgoals.count >= MAX_PER_GOAL
      errors.add(:base, "サブゴールは最大#{MAX_PER_GOAL}つまでです")
    end
  end
end
