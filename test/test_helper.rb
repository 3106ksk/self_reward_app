ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def create_user!(name: "Test User", email: nil, password: "password123")
      User.create!(
        name: name,
        email: email || "user-#{SecureRandom.hex(8)}@example.com",
        password: password,
        password_confirmation: password
      )
    end

    def create_goal_for!(user, title: "Webエンジニアに転職")
      user.create_goal!(
        title: title,
        value_statement: "家族との時間を大切にする",
        description: "理想の働き方を手に入れる"
      )
    end

    def create_subgoal_for!(goal, title: "Rails基礎を学ぶ", position: 1)
      goal.subgoals.create!(
        title: title,
        description: "基礎を固める",
        position: position,
        reward_title: "好きなカフェで休む",
        reward_description: "ここまで進んだ区切り"
      )
    end

    def create_quest_for!(subgoal, title: "RailsガイドでMVCの流れを確認する", position: 1, completed_at: nil, small_reward: nil)
      subgoal.quests.create!(
        title: title,
        description: "クリア条件を満たす",
        position: position,
        completed_at: completed_at,
        small_reward: small_reward,
        small_reward_claimed_at: small_reward.present? ? Time.current : nil
      )
    end

    def create_small_reward_for!(goal, title: "好きなドリンクを飲む")
      goal.small_rewards.create!(title: title)
    end
  end
end

module LoginSupport
  def log_in_as(user, password: "password123")
    post login_path, params: { email: user.email, password: password }
  end
end

class ActionDispatch::IntegrationTest
  include LoginSupport
end
