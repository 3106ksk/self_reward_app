class SubgoalsController < ApplicationController
  before_action :set_goal, only: :create
  before_action :set_subgoal, only: %i[ edit update destroy claim_reward ]

  def create
    @subgoal = @goal.subgoals.build(subgoal_params)
    @subgoal.position ||= next_position(@goal.subgoals)

    if @subgoal.save
      load_goal_map(subgoal: Subgoal.new(goal: @goal, position: next_position(@goal.subgoals)))
      respond_to do |format|
        format.turbo_stream { render_goal_map_stream(form_frame: "subgoal_form", form_partial: "subgoals/form", form_locals: { subgoal: @subgoal, map: @map, goal: @goal }) }
        format.html { redirect_to root_path, notice: "Subgoal was successfully created.", status: :see_other }
      end
    else
      load_goal_map(subgoal: @subgoal)
      respond_to do |format|
        format.turbo_stream { render_goal_map_stream(form_frame: "subgoal_form", form_partial: "subgoals/form", form_locals: { subgoal: @subgoal, map: @map, goal: @goal }, status: :unprocessable_entity) }
        format.html { render "maps/show", status: :unprocessable_entity }
      end
    end
  end

  def edit
    load_goal_map(subgoal: @subgoal)
    render html: helpers.turbo_frame_tag("subgoal_form") {
      render_to_string(partial: "subgoals/form", formats: [ :html ], locals: { subgoal: @subgoal, map: @map, goal: @goal })
    }
  end

  def update
    if @subgoal.update(subgoal_params)
      load_goal_map(subgoal: Subgoal.new(goal: @goal, position: next_position(@goal.subgoals)))
      respond_to do |format|
        format.turbo_stream { render_goal_map_stream(form_frame: "subgoal_form", form_partial: "subgoals/form", form_locals: { subgoal: @subgoal, map: @map, goal: @goal }) }
        format.html { redirect_to root_path, notice: "Subgoal was successfully updated.", status: :see_other }
      end
    else
      load_goal_map(subgoal: @subgoal)
      respond_to do |format|
        format.turbo_stream { render_goal_map_stream(form_frame: "subgoal_form", form_partial: "subgoals/form", form_locals: { subgoal: @subgoal, map: @map, goal: @goal }, status: :unprocessable_entity) }
        format.html { render partial: "subgoals/form", locals: { subgoal: @subgoal, map: @map, goal: @goal }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @subgoal.destroy

    load_goal_map(subgoal: Subgoal.new(goal: @goal, position: next_position(@goal.subgoals)))
    respond_to do |format|
      format.turbo_stream { render_goal_map_stream(form_frame: "subgoal_form", form_partial: "subgoals/form", form_locals: { subgoal: @subgoal, map: @map, goal: @goal }) }
      format.html { redirect_to root_path, notice: "Subgoal was successfully deleted.", status: :see_other }
    end
  end

  def claim_reward
    @subgoal.update!(reward_claimed_at: Time.current) if @subgoal.reward_available?

    load_goal_map(subgoal: Subgoal.new(goal: @goal, position: next_position(@goal.subgoals)))
    respond_to do |format|
      format.turbo_stream { render_goal_map_stream(form_frame: "subgoal_form", form_partial: "subgoals/form", form_locals: { subgoal: @subgoal, map: @map, goal: @goal }) }
      format.html { redirect_to root_path, notice: "Reward point was successfully claimed.", status: :see_other }
    end
  end

  private

  def set_goal
    @goal = params[:goal_id].present? ? Goal.find(params.expect(:goal_id)) : default_goal
  end

  def set_subgoal
    @subgoal = Subgoal.find(params.expect(:id))
    @goal = @subgoal.goal
  end

  def subgoal_params
    params.expect(subgoal: [ :title, :description, :position, :reward_title, :reward_description ])
  end

  def load_goal_map(subgoal: nil)
    @goal ||= default_goal
    @map = @goal
    @subgoals = @goal.subgoals.ordered.includes(:todo_items)
    @todo_items = TodoItem.where(subgoal_id: @subgoals.select(:id)).ordered
    @subgoal = subgoal || Subgoal.new(goal: @goal, position: next_position(@goal.subgoals))
    @todo_item = TodoItem.new(position: 1)
  end

  def default_goal
    @default_goal ||= Goal.ordered.first_or_create!(
      title: "Goal Map",
      value_statement: "Small visible wins compound into the larger reward.",
      description: "Define the route, add checkpoints, and attach visible next actions."
    )
  end

  def render_goal_map_stream(form_frame:, form_partial:, form_locals:, status: :ok)
    render turbo_stream: [
      turbo_stream.replace("goal-map-board", helpers.turbo_frame_tag("goal-map-board", class: "goal-map-board-frame") {
        render_to_string(partial: "maps/map", formats: [ :html ], locals: { map: @map, goal: @goal, subgoals: @subgoals, todo_items: @todo_items })
      }),
      turbo_stream.replace(form_frame, helpers.turbo_frame_tag(form_frame) {
        render_to_string(partial: form_partial, formats: [ :html ], locals: form_locals)
      })
    ], status: status
  end

  def next_position(scope)
    scope.maximum(:position).to_i + 1
  end
end
