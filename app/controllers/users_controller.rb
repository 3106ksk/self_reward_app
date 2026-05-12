class UsersController < ApplicationController
  skip_before_action :require_login, only: %i[new create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      reset_session
      session[:user_id] = @user.id
      redirect_to map_path, success: "アカウントを作成しました。"
    else
      flash.now[:alert] = "アカウント作成に失敗しました。"
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.expect(user: %i[name email password password_confirmation])
  end
end
