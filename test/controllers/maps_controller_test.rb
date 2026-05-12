require "test_helper"

class MapsControllerTest < ActionDispatch::IntegrationTest
  setup do
    TodoItem.delete_all
    Subgoal.delete_all
    Goal.delete_all
    User.delete_all

    @user = create_user!
    @goal = create_goal_for!(@user, title: "Webエンジニアに転職")
    @subgoal = create_subgoal!(@goal, "Rails基礎を学ぶ")
    @todo_item = create_todo_item!(@subgoal, "RailsガイドでMVCの流れを確認する")
  end

  test "redirects root to login when logged out" do
    get root_path

    assert_redirected_to login_path
  end

  test "shows the goal map" do
    log_in_as(@user)

    get root_path

    assert_response :success
    assert_match "ミチシルベ", response.body
    assert_match "目標設定", response.body
    assert_match "価値観設定", response.body
    assert_match "Webエンジニアに転職", response.body
    assert_match "Rails基礎を学ぶ", response.body
    assert_match "RailsガイドでMVCの流れを確認する", response.body
  end

  test "creates one default goal for logged in user" do
    user = create_user!
    expected_title = "目標を設定しましょう"
    expected_value = "今日の一歩が、目指したい未来につながっています。"
    expected_description = "大きな目標、サブゴール、今日のTodoを設定して、道のりを見える形にしましょう。"

    log_in_as(user)

    assert_difference("Goal.count", 1) do
      get root_path
    end

    assert_response :success
    goal = user.reload.goal
    assert_equal expected_title, goal.title
    assert_equal expected_value, goal.value_statement
    assert_equal expected_description, goal.description

    assert_no_difference("Goal.count") do
      get root_path
    end
  end

  test "updates goal and value statement from the side panel" do
    log_in_as(@user)

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
    log_in_as(@user)

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
    log_in_as(@user)

    patch goal_path(@goal), params: {
      goal: { title: "", description: @goal.description, value_statement: "" }
    }

    assert_response :unprocessable_entity
    assert_match "can&#39;t be blank", response.body
  end

  test "creates a subgoal from the side panel flow" do
    log_in_as(@user)

    assert_difference("@goal.subgoals.count", 1) do
      post goal_subgoals_path(@goal), params: {
        subgoal: { title: "ポートフォリオを作る", description: "成果を形にする", position: 2 }
      }
    end

    assert_response :see_other
    assert_equal "ポートフォリオを作る", @goal.subgoals.ordered.last.title
  end

  test "refreshes todo item form subgoal options after turbo subgoal create" do
    other_user = create_user!
    other_goal = create_goal_for!(other_user, title: "他ユーザーの目標")
    create_subgoal!(other_goal, "他ユーザーのサブゴール")

    log_in_as(@user)

    assert_difference("@goal.subgoals.count", 1) do
      post goal_subgoals_path(@goal),
        params: {
          subgoal: { title: "ポートフォリオを作る", description: "成果を形にする", position: 2 }
        },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
    assert_match "target=\"todo_item_form\"", response.body
    assert_match "ポートフォリオを作る", response.body
    assert_no_match "他ユーザーのサブゴール", response.body
  end

  test "does not create more than five subgoals" do
    log_in_as(@user)

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
    log_in_as(@user)

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
    log_in_as(@user)

    assert_difference("@goal.subgoals.count", -1) do
      assert_difference("TodoItem.count", -1) do
        delete subgoal_path(@subgoal)
      end
    end

    assert_response :see_other
    assert_raises(ActiveRecord::RecordNotFound) { @subgoal.reload }
  end

  test "creates a todo item under a subgoal" do
    log_in_as(@user)

    assert_difference("@subgoal.todo_items.count", 1) do
      post subgoal_todo_items_path(@subgoal), params: {
        todo_item: { title: "フォームを1画面作った", memo: "今日 10:45", position: 2 }
      }
    end

    assert_response :see_other
    assert_equal "フォームを1画面作った", @subgoal.todo_items.ordered.last.title
  end

  test "edits and updates a todo item from the map" do
    log_in_as(@user)

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
    log_in_as(@user)

    assert_not @todo_item.completed?

    patch toggle_todo_item_path(@todo_item)

    assert_response :see_other
    assert @todo_item.reload.completed?
  end

  test "claims an available reward point" do
    log_in_as(@user)

    @subgoal.todo_items.update_all(completed_at: Time.current)

    patch claim_reward_subgoal_path(@subgoal)

    assert_response :see_other
    assert @subgoal.reload.reward_claimed?
  end

  test "does not claim a reward point before subgoal completion" do
    log_in_as(@user)

    patch claim_reward_subgoal_path(@subgoal)

    assert_response :see_other
    assert_not @subgoal.reload.reward_claimed?
  end

  test "cannot update another user's goal" do
    other_user = create_user!
    other_goal = create_goal_for!(other_user, title: "他ユーザーの目標")

    log_in_as(@user)

    patch goal_path(other_goal), params: {
      goal: {
        title: "書き換え",
        description: other_goal.description,
        value_statement: other_goal.value_statement
      }
    }

    assert_response :not_found
    assert_equal "他ユーザーの目標", other_goal.reload.title
  end

  test "cannot operate another user's subgoal" do
    other_user = create_user!
    other_goal = create_goal_for!(other_user, title: "他ユーザーの目標")
    other_subgoal = create_subgoal!(other_goal, "他ユーザーのサブゴール")

    log_in_as(@user)

    patch subgoal_path(other_subgoal), params: {
      subgoal: {
        title: "書き換え",
        description: other_subgoal.description,
        position: other_subgoal.position
      }
    }

    assert_response :not_found
    assert_equal "他ユーザーのサブゴール", other_subgoal.reload.title
  end

  test "cannot operate another user's todo item" do
    other_user = create_user!
    other_goal = create_goal_for!(other_user, title: "他ユーザーの目標")
    other_subgoal = create_subgoal!(other_goal, "他ユーザーのサブゴール")
    other_todo_item = create_todo_item!(other_subgoal, "他ユーザーのTodo")

    log_in_as(@user)

    patch todo_item_path(other_todo_item), params: {
      todo_item: {
        title: "書き換え",
        memo: other_todo_item.memo,
        position: other_todo_item.position
      }
    }

    assert_response :not_found
    assert_equal "他ユーザーのTodo", other_todo_item.reload.title
  end

  private

  def create_goal!(title)
    create_goal_for!(create_user!, title: title)
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
