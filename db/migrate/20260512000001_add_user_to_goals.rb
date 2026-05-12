require "bcrypt"
require "securerandom"

class AddUserToGoals < ActiveRecord::Migration[8.0]
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  class MigrationGoal < ActiveRecord::Base
    self.table_name = "goals"
  end

  def up
    add_reference :goals, :user, foreign_key: true, index: false

    MigrationGoal.reset_column_information
    MigrationUser.reset_column_information

    MigrationGoal.where(user_id: nil).find_each do |goal|
      user = MigrationUser.create!(
        name: "移行ユーザー #{goal.id}",
        email: "legacy-goal-#{goal.id}@example.local",
        password_digest: BCrypt::Password.create(SecureRandom.hex(32))
      )

      goal.update!(user_id: user.id)
    end

    change_column_null :goals, :user_id, false
    add_index :goals, :user_id, unique: true
  end

  def down
    remove_index :goals, :user_id
    remove_reference :goals, :user, foreign_key: true
  end
end
