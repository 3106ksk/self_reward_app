require "test_helper"

class MapsControllerTest < ActionDispatch::IntegrationTest
  FORBIDDEN_SERVICE_COPY = [ "Todo", "今日のTodo", "今日やったこと", "今日の一歩", "完了タスク" ]

  setup do
    Quest.delete_all
    SmallReward.delete_all
    Subgoal.delete_all
    Goal.delete_all
    User.delete_all

    @user = create_user!
    @goal = create_goal_for!(@user, title: "Webエンジニアに転職")
    @subgoal = create_subgoal_for!(@goal, title: "Rails基礎を学ぶ")
    @small_reward = create_small_reward_for!(@goal, title: "好きなドリンクを飲む")
    @quest = create_quest_for!(@subgoal, title: "RailsガイドでMVCの流れを確認する")
  end

  test "redirects root to login when logged out" do
    get root_path

    assert_redirected_to login_path
  end

  test "shows the goal map with quest and reward language only" do
    log_in_as(@user)

    get root_path

    assert_response :success
    assert_match "ミチシルベ", response.body
    assert_match "長期ゴール設定", response.body
    assert_match "価値観設定", response.body
    assert_match "Webエンジニアに転職", response.body
    assert_match "Rails基礎を学ぶ", response.body
    assert_match "RailsガイドでMVCの流れを確認する", response.body
    assert_match "クエスト", response.body
    assert_match "小さなご褒美", response.body
    assert_match "大きなご褒美", response.body
    FORBIDDEN_SERVICE_COPY.each { |copy| assert_no_match copy, response.body }
  end

  test "creates one default goal for logged in user with quest language" do
    user = create_user!
    expected_title = "まずは長期ゴールを入力してください"
    expected_value = "このゴールを目指す理由や、大切にしたい価値観を書いてください。"
    expected_description = "ゴールを達成したときの状態や、実現したい暮らしを書いてください。"

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

  test "does not update goal without required values" do
    log_in_as(@user)

    patch goal_path(@goal), params: {
      goal: { title: "", description: @goal.description, value_statement: "" }
    }

    assert_response :unprocessable_entity
    assert_match "can&#39;t be blank", response.body
  end

  test "creates a subgoal at the end even when position param is passed" do
    log_in_as(@user)

    assert_difference("@goal.subgoals.count", 1) do
      post goal_subgoals_path(@goal), params: {
        subgoal: { title: "ポートフォリオを作る", description: "成果を形にする", position: 1 }
      }
    end

    assert_response :see_other
    created = @goal.subgoals.ordered.last
    assert_equal "ポートフォリオを作る", created.title
    assert_equal 2, created.position
  end

  test "subgoal and quest forms do not expose position or forbidden copy" do
    log_in_as(@user)

    get root_path

    assert_response :success
    assert_no_match(/name="subgoal\[position\]"/, response.body)
    assert_no_match(/name="quest\[position\]"/, response.body)
    assert_no_match ">順番<", response.body
    FORBIDDEN_SERVICE_COPY.each { |copy| assert_no_match copy, response.body }
  end

  test "refreshes quest form subgoal options after turbo subgoal create" do
    other_user = create_user!
    other_goal = create_goal_for!(other_user, title: "他ユーザーの目標")
    create_subgoal_for!(other_goal, title: "他ユーザーのサブゴール")

    log_in_as(@user)

    assert_difference("@goal.subgoals.count", 1) do
      post goal_subgoals_path(@goal),
        params: {
          subgoal: { title: "ポートフォリオを作る", description: "成果を形にする", position: 1 }
        },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
    assert_match "target=\"quest_form\"", response.body
    assert_match "ポートフォリオを作る", response.body
    assert_no_match "他ユーザーのサブゴール", response.body
  end

  test "edits and updates a subgoal from the map without changing position" do
    log_in_as(@user)

    get edit_subgoal_path(@subgoal)

    assert_response :success
    assert_match "subgoal_form", response.body
    assert_match "Rails基礎を学ぶ", response.body
    assert_no_match(/name="subgoal\[position\]"/, response.body)

    patch subgoal_path(@subgoal), params: {
      subgoal: { title: "Rails基礎を終える", description: @subgoal.description, position: 99 }
    }

    assert_response :see_other
    assert_equal "Rails基礎を終える", @subgoal.reload.title
    assert_equal 1, @subgoal.position
  end

  test "deletes a subgoal and its quests" do
    log_in_as(@user)

    assert_difference("@goal.subgoals.count", -1) do
      assert_difference("Quest.count", -1) do
        delete subgoal_path(@subgoal)
      end
    end

    assert_response :see_other
    assert_raises(ActiveRecord::RecordNotFound) { @subgoal.reload }
  end

  test "creates a quest under a subgoal at the end even when position param is passed" do
    log_in_as(@user)

    assert_difference("@subgoal.quests.count", 1) do
      post subgoal_quests_path(@subgoal), params: {
        quest: { title: "フォームを1画面作った", description: "入力から保存まで確認", position: 1 }
      }
    end

    assert_response :see_other
    created = @subgoal.quests.ordered.last
    assert_equal "フォームを1画面作った", created.title
    assert_equal 2, created.position
  end

  test "edits and updates a quest from the map without changing position" do
    log_in_as(@user)

    get edit_quest_path(@quest)

    assert_response :success
    assert_match "quest_form", response.body
    assert_match "RailsガイドでMVCの流れを確認する", response.body
    assert_no_match(/name="quest\[position\]"/, response.body)

    patch quest_path(@quest), params: {
      quest: { title: "MVCの流れを整理した", description: "ノートにまとめた", position: 99 }
    }

    assert_response :see_other
    assert_equal "MVCの流れを整理した", @quest.reload.title
    assert_equal 1, @quest.position
  end

  test "completes a quest with a selected small reward" do
    log_in_as(@user)

    assert_not @quest.completed?

    patch complete_quest_path(@quest), params: {
      quest: { small_reward_id: @small_reward.id }
    }

    assert_response :see_other
    @quest.reload
    assert @quest.completed?
    assert_equal @small_reward, @quest.small_reward
    assert @quest.small_reward_claimed_at.present?
  end

  test "uncompletes a quest and clears selected small reward" do
    @quest.update!(
      completed_at: Time.current,
      small_reward: @small_reward,
      small_reward_claimed_at: Time.current
    )
    log_in_as(@user)

    patch uncomplete_quest_path(@quest)

    assert_response :see_other
    @quest.reload
    assert_not @quest.completed?
    assert_nil @quest.small_reward
    assert_nil @quest.small_reward_claimed_at
  end

  test "creates and updates a small reward with title only" do
    log_in_as(@user)

    assert_difference("@goal.small_rewards.count", 1) do
      post small_rewards_path, params: {
        small_reward: { title: "30分だけ動画を見る", memo: "保存しない", position: 1, active: false }
      }
    end

    assert_response :see_other
    reward = @goal.small_rewards.order(:created_at).last
    assert_equal "30分だけ動画を見る", reward.title
    assert_not reward.respond_to?(:memo)
    assert_not reward.respond_to?(:position)
    assert_not reward.respond_to?(:active)

    patch small_reward_path(reward), params: {
      small_reward: { title: "散歩する", memo: "保存しない" }
    }

    assert_response :see_other
    assert_equal "散歩する", reward.reload.title
  end

  test "claims big reward only after all quests are complete" do
    second_quest = create_quest_for!(@subgoal, title: "フォームを1画面作る", position: 2)
    log_in_as(@user)

    @quest.update!(completed_at: Time.current)
    patch claim_reward_subgoal_path(@subgoal)

    assert_response :see_other
    assert_not @subgoal.reload.reward_claimed?

    second_quest.update!(completed_at: Time.current)
    patch claim_reward_subgoal_path(@subgoal)

    assert_response :see_other
    assert @subgoal.reload.reward_claimed?
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

  test "cannot operate another user's quest" do
    other_user = create_user!
    other_goal = create_goal_for!(other_user, title: "他ユーザーの目標")
    other_subgoal = create_subgoal_for!(other_goal, title: "他ユーザーのサブゴール")
    other_quest = create_quest_for!(other_subgoal, title: "他ユーザーのクエスト")

    log_in_as(@user)

    patch quest_path(other_quest), params: {
      quest: { title: "書き換え", description: other_quest.description }
    }

    assert_response :not_found
    assert_equal "他ユーザーのクエスト", other_quest.reload.title

    patch complete_quest_path(other_quest), params: {
      quest: { small_reward_id: @small_reward.id }
    }

    assert_response :not_found
    assert_not other_quest.reload.completed?
  end

  test "cannot operate another user's small reward" do
    other_user = create_user!
    other_goal = create_goal_for!(other_user, title: "他ユーザーの目標")
    other_reward = create_small_reward_for!(other_goal, title: "他ユーザーのご褒美")

    log_in_as(@user)

    patch small_reward_path(other_reward), params: {
      small_reward: { title: "書き換え" }
    }

    assert_response :not_found
    assert_equal "他ユーザーのご褒美", other_reward.reload.title
  end
end
