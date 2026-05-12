class CreateGoals < ActiveRecord::Migration[8.0]
  def change
    create_table :goals do |t|
      t.string :value_statement, null: false
      t.string :title, null: false
      t.text :description

      t.timestamps
    end
  end
end
