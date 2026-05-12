class RenameTodoItemsToQuestsAndAddSmallRewards < ActiveRecord::Migration[8.0]
  def change
    rename_table :todo_items, :quests

    rename_index :quests, "index_todo_items_on_completed_at", "index_quests_on_completed_at" if index_name_exists?(:quests, "index_todo_items_on_completed_at")
    rename_index :quests, "index_todo_items_on_subgoal_id", "index_quests_on_subgoal_id" if index_name_exists?(:quests, "index_todo_items_on_subgoal_id")
    rename_index :quests, "index_todo_items_on_subgoal_id_and_position", "index_quests_on_subgoal_id_and_position" if index_name_exists?(:quests, "index_todo_items_on_subgoal_id_and_position")

    create_table :small_rewards do |t|
      t.references :goal, null: false, foreign_key: true
      t.string :title, null: false

      t.timestamps
    end

    add_reference :quests, :small_reward, foreign_key: true
    add_column :quests, :small_reward_claimed_at, :datetime
  end
end
