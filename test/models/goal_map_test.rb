require "test_helper"

class GoalMapTest < ActiveSupport::TestCase
  setup do
    TodoItem.delete_all
    Subgoal.delete_all
    Goal.delete_all
  end

  test "goal owns ordered subgoals" do
    goal = create_goal!("Webエンジニアに転職")
    second = create_subgoal!(goal, "ポートフォリオを作る", position: 2)
    first = create_subgoal!(goal, "Rails基礎を学ぶ", position: 1)

    assert_includes goal.subgoals, first
    assert_includes goal.subgoals, second
    assert_equal [first, second], goal.subgoals.to_a
  end

  test "subgoal owns ordered todo items" do
    goal = create_goal!("Webエンジニアに転職")
    subgoal = create_subgoal!(goal, "Rails基礎を学ぶ")
    second = create_todo_item!(subgoal, "CRUDアプリを1つ写経する", position: 2)
    first = create_todo_item!(subgoal, "RailsガイドでMVCの流れを確認する", position: 1)

    assert_includes subgoal.todo_items, first
    assert_includes subgoal.todo_items, second
    assert_equal [first, second], subgoal.todo_items.to_a
  end

  test "goal validates title and value statement" do
    goal = Goal.new(title: nil, value_statement: nil)

    assert_not goal.valid?
    assert goal.errors[:title].present?
    assert goal.errors[:value_statement].present?
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
      create_subgoal!(goal, "サブゴール#{index + 1}", position: index + 1)
    end

    sixth = goal.subgoals.build(title: "サブゴール6", description: "多すぎる", position: 6)

    assert_not sixth.valid?
    assert sixth.errors[:base].present?
  end

  test "todo item validates title and position" do
    todo_item = TodoItem.new(title: nil, position: nil)

    assert_not todo_item.valid?
    assert todo_item.errors[:title].present?
    assert todo_item.errors[:position].present?
  end

  test "todo item completion is derived from completed_at" do
    subgoal = create_subgoal!(create_goal!("Webエンジニアに転職"), "Rails基礎を学ぶ")
    todo_item = create_todo_item!(subgoal, "フォームを作る")

    assert_not todo_item.completed?

    todo_item.update!(completed_at: Time.current)

    assert todo_item.completed?
    assert_equal true, todo_item.completed
  end

  test "reward becomes available after every todo is complete" do
    subgoal = create_subgoal!(create_goal!("Webエンジニアに転職"), "Rails基礎を学ぶ")
    first = create_todo_item!(subgoal, "CRUDアプリを1つ写経する")
    second = create_todo_item!(subgoal, "フォームを1画面作る", position: 2)

    assert_not subgoal.completed?
    assert_not subgoal.reward_available?

    first.update!(completed_at: Time.current)
    second.update!(completed_at: Time.current)

    assert subgoal.reload.completed?
    assert subgoal.reward_available?

    subgoal.update!(reward_claimed_at: Time.current)

    assert subgoal.reward_claimed?
    assert_not subgoal.reward_available?
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
      description: "基礎を固める",
      position: position,
      reward_title: "好きなカフェで休む",
      reward_description: "ここまで進んだ区切り"
    )
  end

  def create_todo_item!(subgoal, title, position: 1)
    subgoal.todo_items.create!(title: title, memo: "今日 10:45", position: position)
  end
end
