class TodoItemsController < ApplicationController
  before_action :set_subgoal, only: :create
  before_action :set_todo_item, only: %i[ edit update toggle ]

  def create
    @todo_item = @subgoal.todo_items.build(todo_item_params)
    @todo_item.position ||= next_position(@subgoal.todo_items)

    if @todo_item.save
      load_goal_map(todo_item: TodoItem.new(position: next_position(@subgoal.todo_items)))
      respond_to do |format|
        format.turbo_stream { render_goal_map_stream(form_frame: "todo_item_form", form_partial: "todo_items/form", form_locals: { todo_item: @todo_item, map: @map, goal: @goal }) }
        format.html { redirect_to root_path, notice: "Todo item was successfully created.", status: :see_other }
      end
    else
      load_goal_map(todo_item: @todo_item)
      respond_to do |format|
        format.turbo_stream { render_goal_map_stream(form_frame: "todo_item_form", form_partial: "todo_items/form", form_locals: { todo_item: @todo_item, map: @map, goal: @goal }, status: :unprocessable_entity) }
        format.html { render "maps/show", status: :unprocessable_entity }
      end
    end
  end

  def edit
    load_goal_map(todo_item: @todo_item)
    render html: helpers.turbo_frame_tag("todo_item_form") {
      render_to_string(partial: "todo_items/form", formats: [ :html ], locals: { todo_item: @todo_item, map: @map, goal: @goal })
    }
  end

  def update
    if @todo_item.update(todo_item_params)
      load_goal_map(todo_item: TodoItem.new(position: next_position(@todo_item.subgoal.todo_items)))
      respond_to do |format|
        format.turbo_stream { render_goal_map_stream(form_frame: "todo_item_form", form_partial: "todo_items/form", form_locals: { todo_item: @todo_item, map: @map, goal: @goal }) }
        format.html { redirect_to root_path, notice: "Todo item was successfully updated.", status: :see_other }
      end
    else
      load_goal_map(todo_item: @todo_item)
      respond_to do |format|
        format.turbo_stream { render_goal_map_stream(form_frame: "todo_item_form", form_partial: "todo_items/form", form_locals: { todo_item: @todo_item, map: @map, goal: @goal }, status: :unprocessable_entity) }
        format.html { render partial: "todo_items/form", locals: { todo_item: @todo_item, map: @map, goal: @goal }, status: :unprocessable_entity }
      end
    end
  end

  def toggle
    completed_at = @todo_item.completed? ? nil : Time.current
    @todo_item.update!(completed_at: completed_at)

    load_goal_map(todo_item: TodoItem.new(position: next_position(@todo_item.subgoal.todo_items)))
    respond_to do |format|
      format.turbo_stream { render_goal_map_stream(form_frame: "todo_item_form", form_partial: "todo_items/form", form_locals: { todo_item: @todo_item, map: @map, goal: @goal }) }
      format.html { redirect_to root_path, notice: "Todo item was successfully updated.", status: :see_other }
    end
  end

  private

  def set_subgoal
    @subgoal = if params[:subgoal_id].present?
      owned_subgoals.find(params.expect(:subgoal_id))
    elsif params.dig(:todo_item, :subgoal_id).present?
      owned_subgoals.find(params.dig(:todo_item, :subgoal_id))
    else
      default_goal.subgoals.ordered.first || default_goal.subgoals.create!(title: "First checkpoint", position: 1)
    end
    @goal = @subgoal.goal
  end

  def set_todo_item
    @todo_item = owned_todo_items.find(params.expect(:id))
    @subgoal = @todo_item.subgoal
    @goal = @subgoal.goal
  end

  def todo_item_params
    permitted = params.expect(todo_item: [ :title, :memo, :completed_at, :position, :subgoal_id, :completed ])
    if permitted[:subgoal_id].present?
      permitted[:subgoal_id] = owned_subgoals.find(permitted[:subgoal_id]).id
    end
    completed = permitted.delete(:completed)
    permitted[:completed_at] = ActiveModel::Type::Boolean.new.cast(completed) ? Time.current : nil unless completed.nil?
    permitted
  end

  def load_goal_map(todo_item: nil)
    @goal ||= @subgoal&.goal || default_goal
    @map = @goal
    @subgoals = @goal.subgoals.ordered.includes(:todo_items)
    @todo_items = TodoItem.where(subgoal_id: @subgoals.select(:id)).ordered
    @subgoal = todo_item.subgoal if todo_item&.persisted?
    @subgoal ||= todo_item&.subgoal
    @subgoal ||= @subgoals.first || @goal.subgoals.create!(title: "First checkpoint", position: 1)
    @subgoals = @goal.subgoals.ordered.includes(:todo_items)
    @todo_items = TodoItem.where(subgoal_id: @subgoals.select(:id)).ordered
    @todo_item = todo_item || @subgoal.todo_items.build(position: next_position(@subgoal.todo_items))
  end

  def default_goal
    @default_goal ||= current_user.goal || current_user.create_goal!(
      title: "目標を設定しましょう",
      value_statement: "今日の一歩が、目指したい未来につながっています。",
      description: "大きな目標、サブゴール、今日のTodoを設定して、道のりを見える形にしましょう。"
    )
  end

  def owned_subgoals
    Subgoal.joins(:goal).where(goals: { user_id: current_user.id })
  end

  def owned_todo_items
    TodoItem.joins(subgoal: :goal).where(goals: { user_id: current_user.id })
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
