require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    Quest.delete_all
    SmallReward.delete_all
    Subgoal.delete_all
    Goal.delete_all
    User.delete_all
  end

  test "creates user, logs in, and redirects to root" do
    assert_difference("User.count", 1) do
      post users_path, params: {
        user: {
          name: "New User",
          email: "new-user@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    user = User.find_by!(email: "new-user@example.com")
    assert_redirected_to root_path
    assert_equal user.id, session[:user_id]
  end
end
