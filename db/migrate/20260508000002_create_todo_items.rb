class CreateTodoItems < ActiveRecord::Migration[8.0]
  def change
    create_table :todo_items do |t|
      t.references :subgoal, null: false, foreign_key: true
      t.string :title, null: false
      t.text :memo
      t.datetime :completed_at
      t.integer :position, null: false

      t.timestamps
    end

    add_index :todo_items, [ :subgoal_id, :position ]
    add_index :todo_items, :completed_at
  end
end
