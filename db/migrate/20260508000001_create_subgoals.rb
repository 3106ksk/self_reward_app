class CreateSubgoals < ActiveRecord::Migration[8.0]
  def change
    create_table :subgoals do |t|
      t.references :goal, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :position, null: false

      t.timestamps
    end

    add_index :subgoals, [ :goal_id, :position ]
  end
end
