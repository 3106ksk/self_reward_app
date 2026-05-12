class AddRewardFieldsToSubgoals < ActiveRecord::Migration[8.0]
  def change
    add_column :subgoals, :reward_title, :string
    add_column :subgoals, :reward_description, :text
    add_column :subgoals, :reward_claimed_at, :datetime
  end
end
