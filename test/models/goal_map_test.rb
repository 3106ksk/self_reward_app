require "test_helper"

class GoalMapTest < ActiveSupport::TestCase
  setup do
    Quest.delete_all
    SmallReward.delete_all
    Subgoal.delete_all
    Goal.delete_all
    User.delete_all
  end

  test "goal owns ordered subgoals, quests, and small rewards" do
    goal = create_goal!("Webエンジニアに転職")
    second = create_subgoal_for!(goal, title: "ポートフォリオを作る", position: 2)
    first = create_subgoal_for!(goal, title: "Rails基礎を学ぶ", position: 1)
    reward = create_small_reward_for!(goal, title: "散歩する")

    assert_equal [ first, second ], goal.subgoals.to_a
    assert_includes goal.small_rewards, reward
  end

  test "subgoal owns ordered quests" do
    subgoal = create_subgoal_for!(create_goal!("Webエンジニアに転職"))
    second = create_quest_for!(subgoal, title: "CRUDアプリを1つ写経する", position: 2)
    first = create_quest_for!(subgoal, title: "RailsガイドでMVCの流れを確認する", position: 1)

    assert_includes subgoal.quests, first
    assert_includes subgoal.quests, second
    assert_equal [ first, second ], subgoal.quests.to_a
  end

  test "goal validates title and value statement" do
    goal = Goal.new(user: create_user!, title: nil, value_statement: nil)

    assert_not goal.valid?
    assert goal.errors[:title].present?
    assert goal.errors[:value_statement].present?
  end

  test "goal belongs to a user" do
    goal = Goal.new(
      title: "Webエンジニアに転職",
      value_statement: "家族との時間を大切にする",
      description: "理想の働き方を手に入れる"
    )

    assert_not goal.valid?
    assert goal.errors[:user].present?
  end

  test "user can have only one goal" do
    user = create_user!
    create_goal_for!(user, title: "最初の目標")

    second_goal = Goal.new(
      user: user,
      title: "2つ目の目標",
      value_statement: "別の価値観",
      description: "重複した目標"
    )

    assert_not second_goal.valid?
    assert second_goal.errors[:user_id].present?
  end

  test "subgoal validates title and position" do
    subgoal = Subgoal.new(title: nil, position: nil)

    assert_not subgoal.valid?
    assert subgoal.errors[:title].present?
    assert subgoal.errors[:position].present?
  end

  test "goal can have at most five subgoals" do
    goal = create_goal!("Webエンジニアに転職")
    5.times do |index|
      create_subgoal_for!(goal, title: "サブゴール#{index + 1}", position: index + 1)
    end

    sixth = goal.subgoals.build(title: "サブゴール6", description: "多すぎる", position: 6)

    assert_not sixth.valid?
    assert sixth.errors[:base].present?
  end

  test "quest validates title and position" do
    quest = Quest.new(title: nil, position: nil)

    assert_not quest.valid?
    assert quest.errors[:title].present?
    assert quest.errors[:position].present?
  end

  test "small reward validates title and belongs to goal" do
    reward = SmallReward.new(title: nil)

    assert_not reward.valid?
    assert reward.errors[:title].present?
    assert reward.errors[:goal].present?
  end

  test "quest completion is derived from completed_at" do
    subgoal = create_subgoal_for!(create_goal!("Webエンジニアに転職"))
    quest = create_quest_for!(subgoal, title: "フォームを作る")

    assert_not quest.completed?

    quest.update!(completed_at: Time.current)

    assert quest.completed?
    assert_equal true, quest.completed
  end

  test "quest can be linked to a selected small reward" do
    goal = create_goal!("Webエンジニアに転職")
    subgoal = create_subgoal_for!(goal)
    reward = create_small_reward_for!(goal, title: "散歩する")
    quest = create_quest_for!(subgoal, title: "フォームを作る")

    quest.update!(
      completed_at: Time.current,
      small_reward: reward,
      small_reward_claimed_at: Time.current
    )

    assert_equal reward, quest.reload.small_reward
    assert quest.small_reward_claimed_at.present?
  end

  test "big reward becomes available only after every quest is complete" do
    subgoal = create_subgoal_for!(create_goal!("Webエンジニアに転職"))
    first = create_quest_for!(subgoal, title: "CRUDアプリを1つ写経する")
    second = create_quest_for!(subgoal, title: "フォームを1画面作る", position: 2)

    assert_not subgoal.completed?
    assert_not subgoal.reward_available?

    first.update!(completed_at: Time.current)
    assert_not subgoal.reload.completed?
    assert_not subgoal.reward_available?

    second.update!(completed_at: Time.current)
    assert subgoal.reload.completed?
    assert subgoal.reward_available?

    subgoal.update!(reward_claimed_at: Time.current)
    assert subgoal.reward_claimed?
    assert_not subgoal.reward_available?
  end

  private

  def create_goal!(title)
    create_goal_for!(create_user!, title: title)
  end
end
