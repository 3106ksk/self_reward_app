require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    TodoItem.delete_all
    Subgoal.delete_all
    Goal.delete_all
    User.delete_all
  end

  test "is valid with name email and password" do
    user = User.new(
      name: "Test User",
      email: "user@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    assert user.valid?
  end

  test "email must be unique" do
    create_user!(email: "duplicate@example.com")
    user = User.new(
      name: "Another User",
      email: "duplicate@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    assert_not user.valid?
    assert user.errors[:email].present?
  end

  test "password must be at least eight characters" do
    user = User.new(
      name: "Test User",
      email: "short-password@example.com",
      password: "short",
      password_confirmation: "short"
    )

    assert_not user.valid?
    assert user.errors[:password].present?
  end

  test "authenticates only with correct password" do
    user = create_user!(password: "password123")

    assert_equal user, user.authenticate("password123")
    assert_not user.authenticate("wrong-password")
  end
end
