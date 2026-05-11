require "application_system_test_case"

class MapsTest < ApplicationSystemTestCase
  setup do
    TodoItem.delete_all
    Subgoal.delete_all
    Goal.delete_all

    @goal = create_goal!("Webエンジニアに転職")
    @subgoal = create_subgoal!(@goal, "Rails基礎を学ぶ")
    create_todo_item!(@subgoal, "RailsガイドでMVCの流れを確認する")
  end

  test "root displays the goal map and supports adding a todo" do
    visit root_path

    assert_text "目的地までの道のり"
    assert_text "Webエンジニアに転職"
    assert_text "Rails基礎を学ぶ"
    assert_text "RailsガイドでMVCの流れを確認する"

    fill_in "todo_item_title", with: "フォームを1画面作った"
    fill_in "todo_item_memo", with: "今日 10:45"
    click_button "一歩を追加"

    assert_text "フォームを1画面作った"
  end

  private

  def create_goal!(title)
    Goal.create!(
      title: title,
      value_statement: "家族との時間を大切にする",
      description: "理想の働き方を手に入れる"
    )
  end

  def create_subgoal!(goal, title)
    goal.subgoals.create!(title: title, description: "基礎を固める", position: 1)
  end

  def create_todo_item!(subgoal, title)
    subgoal.todo_items.create!(title: title, memo: "今日 10:45", position: 1)
  end
end
