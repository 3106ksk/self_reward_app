class MapsController < ApplicationController
  def show
    load_goal_map
  end

  private

  def load_goal_map
    @goal = Goal.ordered.first_or_create!(
      title: "Goal Map",
      value_statement: "Small visible wins compound into the larger reward.",
      description: "Define the route, add checkpoints, and attach visible next actions."
    )
    @map = @goal
    @subgoals = @goal.subgoals.ordered.includes(:todo_items)
    @todo_items = TodoItem.where(subgoal_id: @subgoals.select(:id)).ordered
    @subgoal = Subgoal.new(goal: @goal, position: next_position(@goal.subgoals))
    @todo_item = TodoItem.new(position: 1)
  end

  def next_position(scope)
    scope.maximum(:position).to_i + 1
  end
end
