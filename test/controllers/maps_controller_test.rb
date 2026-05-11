require "test_helper"

class MapsControllerTest < ActionDispatch::IntegrationTest
  setup do
    TodoItem.delete_all
    Subgoal.delete_all
    Goal.delete_all

    @goal = create_goal!("Webエンジニアに転職")
    @subgoal = create_subgoal!(@goal, "Rails基礎を学ぶ")
    @todo_item = create_todo_item!(@subgoal, "RailsガイドでMVCの流れを確認する")
  end

  test "shows the goal map" do
    get root_path

    assert_response :success
    assert_match "ミチシルベ", response.body
    assert_match "目標設定", response.body
    assert_match "価値観設定", response.body
    assert_match "Webエンジニアに転職", response.body
    assert_match "Rails基礎を学ぶ", response.body
    assert_match "RailsガイドでMVCの流れを確認する", response.body
  end

  test "updates goal and value statement from the side panel" do
    patch goal_path(@goal), params: {
      goal: {
        title: "フリーランスWebエンジニアになる",
        description: "場所に縛られず働く",
        value_statement: "家族との時間を最優先にする"
      }
    }

    assert_response :see_other
    assert_equal "フリーランスWebエンジニアになる", @goal.reload.title
    assert_equal "家族との時間を最優先にする", @goal.value_statement
  end

  test "updates only the value statement from the side panel" do
    patch goal_path(@goal), params: {
      goal: {
        title: @goal.title,
        description: @goal.description,
        value_statement: "毎日の積み重ねを大切にする"
      }
    }

    assert_response :see_other
    assert_equal "Webエンジニアに転職", @goal.reload.title
    assert_equal "毎日の積み重ねを大切にする", @goal.value_statement
  end

  test "does not update goal without required values" do
    patch goal_path(@goal), params: {
      goal: { title: "", description: @goal.description, value_statement: "" }
    }

    assert_response :unprocessable_entity
    assert_match "can&#39;t be blank", response.body
  end

  test "creates a subgoal from the side panel flow" do
    assert_difference("@goal.subgoals.count", 1) do
      post goal_subgoals_path(@goal), params: {
        subgoal: { title: "ポートフォリオを作る", description: "成果を形にする", position: 2 }
      }
    end

    assert_response :see_other
    assert_equal "ポートフォリオを作る", @goal.subgoals.ordered.last.title
  end

  test "does not create more than five subgoals" do
    4.times do |index|
      create_subgoal!(@goal, "追加サブゴール#{index + 1}", position: index + 2)
    end

    assert_no_difference("@goal.subgoals.count") do
      post goal_subgoals_path(@goal), params: {
        subgoal: { title: "6つ目のサブゴール", description: "上限超過", position: 6 }
      }
    end

    assert_response :unprocessable_entity
    assert_match "サブゴールは最大5つまでです", response.body
  end

  test "edits and updates a subgoal from the map" do
    get edit_subgoal_path(@subgoal)

    assert_response :success
    assert_match "subgoal_form", response.body
    assert_match "Rails基礎を学ぶ", response.body

    patch subgoal_path(@subgoal), params: {
      subgoal: { title: "Rails基礎を終える", description: @subgoal.description, position: @subgoal.position }
    }

    assert_response :see_other
    assert_equal "Rails基礎を終える", @subgoal.reload.title
  end

  test "deletes a subgoal and its todo items" do
    assert_difference("@goal.subgoals.count", -1) do
      assert_difference("TodoItem.count", -1) do
        delete subgoal_path(@subgoal)
      end
    end

    assert_response :see_other
    assert_raises(ActiveRecord::RecordNotFound) { @subgoal.reload }
  end

  test "creates a todo item under a subgoal" do
    assert_difference("@subgoal.todo_items.count", 1) do
      post subgoal_todo_items_path(@subgoal), params: {
        todo_item: { title: "フォームを1画面作った", memo: "今日 10:45", position: 2 }
      }
    end

    assert_response :see_other
    assert_equal "フォームを1画面作った", @subgoal.todo_items.ordered.last.title
  end

  test "edits and updates a todo item from the map" do
    get edit_todo_item_path(@todo_item)

    assert_response :success
    assert_match "todo_item_form", response.body
    assert_match "RailsガイドでMVCの流れを確認する", response.body

    patch todo_item_path(@todo_item), params: {
      todo_item: { title: "MVCの流れを整理した", memo: "昨日 21:30", position: @todo_item.position }
    }

    assert_response :see_other
    assert_equal "MVCの流れを整理した", @todo_item.reload.title
  end

  test "toggles a todo item into the completed list" do
    assert_not @todo_item.completed?

    patch toggle_todo_item_path(@todo_item)

    assert_response :see_other
    assert @todo_item.reload.completed?
  end

  test "claims an available reward point" do
    @subgoal.todo_items.update_all(completed_at: Time.current)

    patch claim_reward_subgoal_path(@subgoal)

    assert_response :see_other
    assert @subgoal.reload.reward_claimed?
  end

  test "does not claim a reward point before subgoal completion" do
    patch claim_reward_subgoal_path(@subgoal)

    assert_response :see_other
    assert_not @subgoal.reload.reward_claimed?
  end

  private

  def create_goal!(title)
    Goal.create!(
      title: title,
      value_statement: "家族との時間を大切にする",
      description: "理想の働き方を手に入れる"
    )
  end

  def create_subgoal!(goal, title, position: 1)
    goal.subgoals.create!(
      title: title,
      description: "基礎を固めて、自信をつける",
      position: position,
      reward_title: "好きなカフェで休む",
      reward_description: "ここまで進んだ区切り"
    )
  end

  def create_todo_item!(subgoal, title)
    subgoal.todo_items.create!(title: title, memo: "今日 10:45", position: 1)
  end
end
