class GoalsController < ApplicationController
  before_action :set_goal

  def update
    if @goal.update(goal_params)
      load_goal_map
      respond_to do |format|
        format.turbo_stream { render_goal_stream(goal: @goal) }
        format.html { redirect_to root_path, notice: "Goal was successfully updated.", status: :see_other }
      end
    else
      load_goal_map
      respond_to do |format|
        format.turbo_stream { render_goal_stream(goal: @goal, status: :unprocessable_entity) }
        format.html { render "maps/show", status: :unprocessable_entity }
      end
    end
  end

  private

  def set_goal
    @goal = Goal.find(params.expect(:id))
  end

  def goal_params
    params.expect(goal: [ :title, :description, :value_statement ])
  end

  def load_goal_map
    @map = @goal
    @subgoals = @goal.subgoals.ordered.includes(:todo_items)
    @todo_items = TodoItem.where(subgoal_id: @subgoals.select(:id)).ordered
    @subgoal = Subgoal.new(goal: @goal, position: next_position(@goal.subgoals))
    @todo_item = TodoItem.new(position: 1)
  end

  def render_goal_stream(goal:, status: :ok)
    render turbo_stream: [
      turbo_stream.replace("goal-map-board", helpers.turbo_frame_tag("goal-map-board", class: "goal-map-board-frame") {
        render_to_string(partial: "maps/map", formats: [ :html ], locals: { map: @map, goal: @goal, subgoals: @subgoals, todo_items: @todo_items })
      }),
      turbo_stream.replace("goal_form", helpers.turbo_frame_tag("goal_form", data: { action: "turbo:frame-render->goal-map#openPanelSection" }) {
        render_to_string(partial: "goals/goal_form", formats: [ :html ], locals: { goal: goal })
      }),
      turbo_stream.replace("goal_value_form", helpers.turbo_frame_tag("goal_value_form", data: { action: "turbo:frame-render->goal-map#openPanelSection" }) {
        render_to_string(partial: "goals/value_form", formats: [ :html ], locals: { goal: goal })
      })
    ], status: status
  end

  def next_position(scope)
    scope.maximum(:position).to_i + 1
  end
end
