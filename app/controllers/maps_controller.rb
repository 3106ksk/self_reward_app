class MapsController < ApplicationController
  def show
    load_goal_map
  end

  private

  def load_goal_map
    @goal = default_goal
    @map = @goal
    @subgoals = @goal.subgoals.ordered.includes(:quests)
    @quests = Quest.where(subgoal_id: @subgoals.select(:id)).ordered
    @subgoal = Subgoal.new(goal: @goal, position: next_position(@goal.subgoals))
    @quest = Quest.new(position: 1)
    @small_reward = SmallReward.new(goal: @goal)
    @small_rewards = @goal.small_rewards.order(created_at: :asc, id: :asc)
  end

  def default_goal
    current_user.goal || current_user.create_goal!(
      title: "まずは長期ゴールを入力してください",
      value_statement: "このゴールを目指す理由や、大切にしたい価値観を書いてください。",
      description: "ゴールを達成したときの状態や、実現したい暮らしを書いてください。"
    )
  end

  def next_position(scope)
    scope.maximum(:position).to_i + 1
  end
end
