class Quest < ApplicationRecord
  belongs_to :subgoal, inverse_of: :quests
  belongs_to :small_reward, optional: true

  validates :title, presence: true
  validates :position, presence: true, numericality: { only_integer: true }

  scope :ordered, -> { order(position: :asc, created_at: :asc, id: :asc) }
  scope :incomplete, -> { where(completed_at: nil) }
  scope :completed, -> { where.not(completed_at: nil) }

  def completed
    completed?
  end

  def completed?
    completed_at.present?
  end

  def description
    memo
  end

  def description=(value)
    self.memo = value
  end
end
