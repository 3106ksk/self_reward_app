class MapsController < ApplicationController
  def show
    load_goal_map
  end

  private

  def load_goal_map
    @goal = default_goal
    @map = @goal
    @subgoals = @goal.subgoals.ordered.includes(:todo_items)
    @todo_items = TodoItem.where(subgoal_id: @subgoals.select(:id)).ordered
    @subgoal = Subgoal.new(goal: @goal, position: next_position(@goal.subgoals))
    @todo_item = TodoItem.new(position: 1)
  end

  def default_goal
    current_user.goal || current_user.create_goal!(
      title: "目標を設定しましょう",
      value_statement: "今日の一歩が、目指したい未来につながっています。",
      description: "大きな目標、サブゴール、今日のTodoを設定して、道のりを見える形にしましょう。"
    )
  end

  def next_position(scope)
    scope.maximum(:position).to_i + 1
  end
end
