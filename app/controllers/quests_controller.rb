class QuestsController < ApplicationController
  before_action :set_subgoal, only: :create
  before_action :set_quest, only: %i[ edit update complete uncomplete ]

  def create
    @quest = @subgoal.quests.build(quest_params)
    @quest.position = next_position(@subgoal.quests)

    if @quest.save
      load_goal_map(quest: Quest.new(position: next_position(@subgoal.quests)))
      respond_to do |format|
        format.turbo_stream { render_goal_map_stream(form_frame: "quest_form", form_partial: "quests/form", form_locals: { quest: @quest, map: @map, goal: @goal }) }
        format.html { redirect_to root_path, notice: "Quest was successfully created.", status: :see_other }
      end
    else
      load_goal_map(quest: @quest)
      respond_to do |format|
        format.turbo_stream { render_goal_map_stream(form_frame: "quest_form", form_partial: "quests/form", form_locals: { quest: @quest, map: @map, goal: @goal }, status: :unprocessable_entity) }
        format.html { render "maps/show", status: :unprocessable_entity }
      end
    end
  end

  def edit
    load_goal_map(quest: @quest)
    render html: helpers.turbo_frame_tag("quest_form") {
      render_to_string(partial: "quests/form", formats: [ :html ], locals: { quest: @quest, map: @map, goal: @goal })
    }
  end

  def update
    if @quest.update(quest_params)
      load_goal_map(quest: Quest.new(position: next_position(@quest.subgoal.quests)))
      respond_to do |format|
        format.turbo_stream { render_goal_map_stream(form_frame: "quest_form", form_partial: "quests/form", form_locals: { quest: @quest, map: @map, goal: @goal }) }
        format.html { redirect_to root_path, notice: "Quest was successfully updated.", status: :see_other }
      end
    else
      load_goal_map(quest: @quest)
      respond_to do |format|
        format.turbo_stream { render_goal_map_stream(form_frame: "quest_form", form_partial: "quests/form", form_locals: { quest: @quest, map: @map, goal: @goal }, status: :unprocessable_entity) }
        format.html { render partial: "quests/form", locals: { quest: @quest, map: @map, goal: @goal }, status: :unprocessable_entity }
      end
    end
  end

  def complete
    small_reward = current_user.goal.small_rewards.find(complete_params.fetch(:small_reward_id))
    @quest.update!(
      completed_at: Time.current,
      small_reward: small_reward,
      small_reward_claimed_at: Time.current
    )

    load_goal_map(quest: Quest.new(position: next_position(@quest.subgoal.quests)))
    respond_to do |format|
      format.turbo_stream { render_goal_map_stream(form_frame: "quest_form", form_partial: "quests/form", form_locals: { quest: @quest, map: @map, goal: @goal }) }
      format.html { redirect_to root_path, notice: "Quest was successfully completed.", status: :see_other }
    end
  end

  def uncomplete
    @quest.update!(
      completed_at: nil,
      small_reward_id: nil,
      small_reward_claimed_at: nil
    )

    load_goal_map(quest: Quest.new(position: next_position(@quest.subgoal.quests)))
    respond_to do |format|
      format.turbo_stream { render_goal_map_stream(form_frame: "quest_form", form_partial: "quests/form", form_locals: { quest: @quest, map: @map, goal: @goal }) }
      format.html { redirect_to root_path, notice: "Quest was successfully updated.", status: :see_other }
    end
  end

  private

  def set_subgoal
    @subgoal = if params[:subgoal_id].present?
      owned_subgoals.find(params.expect(:subgoal_id))
    elsif params.dig(:quest, :subgoal_id).present?
      owned_subgoals.find(params.dig(:quest, :subgoal_id))
    else
      default_goal.subgoals.ordered.first || default_goal.subgoals.create!(title: "最初のサブゴールを入力してください", position: 1)
    end
    @goal = @subgoal.goal
  end

  def set_quest
    @quest = owned_quests.find(params.expect(:id))
    @subgoal = @quest.subgoal
    @goal = @subgoal.goal
  end

  def quest_params
    permitted = params.expect(quest: [ :title, :memo, :description, :subgoal_id ])
    if permitted[:subgoal_id].present?
      permitted[:subgoal_id] = owned_subgoals.find(permitted[:subgoal_id]).id
    end
    permitted[:memo] = permitted.delete(:description) if permitted.key?(:description)
    permitted
  end

  def complete_params
    params.expect(quest: [ :small_reward_id ])
  end

  def load_goal_map(quest: nil)
    @goal ||= @subgoal&.goal || default_goal
    @map = @goal
    @subgoals = @goal.subgoals.ordered.includes(:quests)
    @quests = Quest.where(subgoal_id: @subgoals.select(:id)).ordered
    @small_rewards = @goal.small_rewards.order(created_at: :asc, id: :asc)
    @subgoal = quest.subgoal if quest&.persisted?
    @subgoal ||= quest&.subgoal
    @subgoal ||= @subgoals.first || @goal.subgoals.create!(title: "最初のサブゴールを入力してください", position: 1)
    @subgoals = @goal.subgoals.ordered.includes(:quests)
    @quests = Quest.where(subgoal_id: @subgoals.select(:id)).ordered
    @quest = quest || @subgoal.quests.build(position: next_position(@subgoal.quests))
    @small_reward = SmallReward.new(goal: @goal)
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

  def owned_quests
    Quest.joins(subgoal: :goal).where(goals: { user_id: current_user.id })
  end

  def render_goal_map_stream(form_frame:, form_partial:, form_locals:, status: :ok)
    render turbo_stream: [
      turbo_stream.replace("goal-map-board", helpers.turbo_frame_tag("goal-map-board", class: "goal-map-board-frame") {
        render_to_string(partial: "maps/map", formats: [ :html ], locals: { map: @map, goal: @goal, subgoals: @subgoals, quests: @quests })
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
