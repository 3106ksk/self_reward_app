# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

def seed_attribute(model_class, *candidates)
  candidates.find { |candidate| model_class.column_names.include?(candidate.to_s) }
end

def seed_assign(record, attributes)
  attributes.each do |attribute, value|
    record.public_send("#{attribute}=", value) if attribute && record.respond_to?("#{attribute}=")
  end
end

if defined?(Goal) && defined?(Subgoal) && defined?(TodoItem)
  goal_title_attribute = seed_attribute(Goal, :title, :name)
  goal_value_attribute = seed_attribute(Goal, :value_statement, :value, :description, :purpose)
  goal_position_attribute = seed_attribute(Goal, :position, :sort_order, :display_order)

  subgoal_title_attribute = seed_attribute(Subgoal, :title, :name)
  subgoal_position_attribute = seed_attribute(Subgoal, :position, :sort_order, :display_order)

  todo_title_attribute = seed_attribute(TodoItem, :title, :name, :body, :content)
  todo_position_attribute = seed_attribute(TodoItem, :position, :sort_order, :display_order)
  todo_completed_attribute = seed_attribute(TodoItem, :completed, :done)

  goal = Goal.find_or_initialize_by(goal_title_attribute => "Webエンジニアに転職")
  seed_assign(
    goal,
    goal_value_attribute => "家族との時間を大切にしながら、場所に縛られず働けるスキルを身につける。",
    goal_position_attribute => 1
  )
  goal.save!

  [
    [
      "Rails基礎を学ぶ",
      "好きなカフェで30分休む",
      "基礎を固めた区切りに、安心して一息つく。",
      [
        "RailsガイドでMVCの流れを確認する",
        "CRUDアプリを1つ写経する",
        "毎日30分、Rubyの復習をする"
      ]
    ],
    [
      "ポートフォリオを作る",
      "小さなお祝いランチ",
      "成果を形にできた自分を認める。",
      [
        "アプリの課題と利用者を1文で書く",
        "Goal/Subgoal/TodoItemの基本機能を実装する",
        "READMEに使い方と工夫した点をまとめる"
      ]
    ],
    [
      "応募準備をする",
      "夜はPCを閉じて映画を見る",
      "応募できる状態まで整えた区切りを作る。",
      [
        "職務経歴書をWebエンジニア向けに更新する",
        "応募したい企業を10社リストアップする",
        "面接で話す開発エピソードを3つ整理する"
      ]
    ]
  ].each.with_index(1) do |(subgoal_title, reward_title, reward_description, todo_titles), subgoal_index|
    subgoal = goal.subgoals.find_or_initialize_by(subgoal_title_attribute => subgoal_title)
    seed_assign(
      subgoal,
      subgoal_position_attribute => subgoal_index,
      seed_attribute(Subgoal, :reward_title) => reward_title,
      seed_attribute(Subgoal, :reward_description) => reward_description
    )
    subgoal.save!

    todo_titles.each.with_index(1) do |todo_title, todo_index|
      todo_item = subgoal.todo_items.find_or_initialize_by(todo_title_attribute => todo_title)
      seed_assign(
        todo_item,
        todo_position_attribute => todo_index,
        todo_completed_attribute => false
      )
      todo_item.save!
    end
  end
else
  warn "Skipping goal-map seed data because Goal, Subgoal, or TodoItem is not defined yet."
end
