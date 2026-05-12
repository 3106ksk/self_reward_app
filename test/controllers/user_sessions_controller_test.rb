require "test_helper"

class UserSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Quest.delete_all
    SmallReward.delete_all
    Subgoal.delete_all
    Goal.delete_all
    User.delete_all

    @user = create_user!(email: "login@example.com", password: "password123")
  end

  test "logs in with valid credentials" do
    post login_path, params: { email: @user.email, password: "password123" }

    assert_redirected_to root_path
    assert_equal @user.id, session[:user_id]
  end

  test "does not log in with invalid credentials" do
    post login_path, params: { email: @user.email, password: "wrong-password" }

    assert_response :unprocessable_entity
    assert_nil session[:user_id]
    assert_match "メールアドレスまたはパスワードが正しくありません。", response.body
  end

  test "logs out and clears session" do
    log_in_as(@user)
    assert_equal @user.id, session[:user_id]

    delete logout_path

    assert_redirected_to login_path
    assert_nil session[:user_id]
  end
end
