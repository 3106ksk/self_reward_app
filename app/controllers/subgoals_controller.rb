class SubgoalsController < ApplicationController
  before_action :set_goal, only: :create
  before_action :set_subgoal, only: %i[ edit update destroy claim_reward ]

  def create
    @subgoal = @goal.subgoals.build(subgoal_params)
    @subgoal.position = next_position(@goal.subgoals)

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
        format.html { redirect_to root_path, notice: "大きなご褒美を獲得しました。", status: :see_other }
    end
  end

  private

  def set_goal
    @goal = default_goal
    return unless params[:goal_id].present?

    raise ActiveRecord::RecordNotFound unless @goal.id == params.expect(:goal_id).to_i
  end

  def set_subgoal
    @subgoal = owned_subgoals.find(params.expect(:id))
    @goal = @subgoal.goal
  end

  def subgoal_params
    params.expect(subgoal: [ :title, :description, :reward_title, :reward_description ])
  end

  def load_goal_map(subgoal: nil)
    @goal ||= default_goal
    @map = @goal
    @subgoals = @goal.subgoals.ordered.includes(:quests)
    @quests = Quest.where(subgoal_id: @subgoals.select(:id)).ordered
    @subgoal = subgoal || Subgoal.new(goal: @goal, position: next_position(@goal.subgoals))
    @quest = Quest.new(position: 1)
    @small_reward = SmallReward.new(goal: @goal)
    @small_rewards = @goal.small_rewards.order(created_at: :asc, id: :asc)
  end

  def default_goal
    @default_goal ||= current_user.goal || current_user.create_goal!(
      title: "まずは長期ゴールを入力してください",
      value_statement: "このゴールを目指す理由や、大切にしたい価値観を書いてください。",
      description: "ゴールを達成したときの状態や、実現したい暮らしを書いてください。"
    )
  end

  def owned_subgoals
    Subgoal.joins(:goal).where(goals: { user_id: current_user.id })
  end

  def render_goal_map_stream(form_frame:, form_partial:, form_locals:, status: :ok)
    render turbo_stream: [
      turbo_stream.replace("goal-map-board", helpers.turbo_frame_tag("goal-map-board", class: "goal-map-board-frame") {
        render_to_string(partial: "maps/map", formats: [ :html ], locals: { map: @map, goal: @goal, subgoals: @subgoals, quests: @quests })
      }),
      turbo_stream.replace(form_frame, helpers.turbo_frame_tag(form_frame) {
        render_to_string(partial: form_partial, formats: [ :html ], locals: form_locals)
      }),
      turbo_stream.replace("quest_form", helpers.turbo_frame_tag("quest_form", data: { action: "turbo:frame-render->goal-map#openPanelSection" }) {
        render_to_string(partial: "quests/form", formats: [ :html ], locals: { quest: @quest, map: @map, goal: @goal })
      })
    ], status: status
  end

  def next_position(scope)
    scope.maximum(:position).to_i + 1
  end
end
