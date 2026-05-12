class SmallRewardsController < ApplicationController
  before_action :set_goal, only: :create
  before_action :set_small_reward, only: %i[ edit update ]

  def create
    @small_reward = @goal.small_rewards.build(small_reward_params)

    if @small_reward.save
      load_goal_map
      respond_to do |format|
        format.turbo_stream { render_goal_map_stream(form_frame: "small_reward_form", form_partial: "small_rewards/form", form_locals: { small_reward: SmallReward.new(goal: @goal), goal: @goal }) }
        format.html { redirect_to root_path, notice: "Small reward was successfully created.", status: :see_other }
      end
    else
      load_goal_map
      respond_to do |format|
        format.turbo_stream { render_goal_map_stream(form_frame: "small_reward_form", form_partial: "small_rewards/form", form_locals: { small_reward: @small_reward, goal: @goal }, status: :unprocessable_entity) }
        format.html { render "maps/show", status: :unprocessable_entity }
      end
    end
  end

  def edit
    load_goal_map
    render html: helpers.turbo_frame_tag("small_reward_form") {
      render_to_string(partial: "small_rewards/form", formats: [ :html ], locals: { small_reward: @small_reward, goal: @goal })
    }
  end

  def update
    if @small_reward.update(small_reward_params)
      load_goal_map
      respond_to do |format|
        format.turbo_stream { render_goal_map_stream(form_frame: "small_reward_form", form_partial: "small_rewards/form", form_locals: { small_reward: SmallReward.new(goal: @goal), goal: @goal }) }
        format.html { redirect_to root_path, notice: "Small reward was successfully updated.", status: :see_other }
      end
    else
      load_goal_map
      respond_to do |format|
        format.turbo_stream { render_goal_map_stream(form_frame: "small_reward_form", form_partial: "small_rewards/form", form_locals: { small_reward: @small_reward, goal: @goal }, status: :unprocessable_entity) }
        format.html { render partial: "small_rewards/form", locals: { small_reward: @small_reward, goal: @goal }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_goal
    @goal = default_goal
  end

  def set_small_reward
    @small_reward = current_user.goal.small_rewards.find(params.expect(:id))
    @goal = @small_reward.goal
  end

  def small_reward_params
    params.expect(small_reward: [ :title ])
  end

  def load_goal_map
    @map = @goal
    @subgoals = @goal.subgoals.ordered.includes(:quests)
    @quests = Quest.where(subgoal_id: @subgoals.select(:id)).ordered
    @subgoal = Subgoal.new(goal: @goal, position: next_position(@goal.subgoals))
    @quest = Quest.new(position: 1)
    @small_rewards = @goal.small_rewards.order(created_at: :asc, id: :asc)
  end

  def default_goal
    @default_goal ||= current_user.goal || current_user.create_goal!(
      title: "まずは長期ゴールを入力してください",
      value_statement: "このゴールを目指す理由や、大切にしたい価値観を書いてください。",
      description: "ゴールを達成したときの状態や、実現したい暮らしを書いてください。"
    )
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
