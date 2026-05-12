class DropPosts < ActiveRecord::Migration[8.0]
  def change
    drop_table :posts do |t|
      t.string :title

      t.timestamps
    end
  end
end
