# ユーザーセッション機能 設計書

## 目的

現行プロジェクト`self_reward_app`に、Deviseを使わず自作のアカウント作成・ログイン・ログアウト機能を追加する。

前回プロジェクト`tips_share_app`では、`has_secure_password`とRails標準の`session`を使ってユーザーセッションを実装していた。この設計ではその方針を引き継ぎつつ、現行アプリの`Goal` / `Subgoal` / `TodoItem`をログインユーザーごとのデータとして扱えるようにする。

今回のアプリ要件は「ユーザー1人が1つの目標を持ち、その目標に複数のサブゴール、各サブゴールに複数のTodoを持つ」構造とする。そのため、`User`と`Goal`の関係は1対多ではなく1対1で設計する。

## 前回プロジェクトから確認した実装

参照元: `/Users/310tea/Documents/Project/tips_share_app`

### 使用していた仕組み

- `Gemfile`
  - `gem "bcrypt", "~> 3.1.7"`
- `User`モデル
  - `has_secure_password`
  - `name`, `email`, `password_digest`
  - `email`に一意制約
- `ApplicationController`
  - `helper_method :logged_in?, :current_user`
  - `before_action :require_login`
  - `session[:user_id]`からログイン中ユーザーを取得
- `UsersController`
  - `new`, `create`
  - アカウント作成後はログイン画面へ誘導
- `UserSessionsController`
  - `new`, `create`, `destroy`
  - `User.find_by(email: params[:email])&.authenticate(params[:password])`
  - ログイン成功時に`session[:user_id] = @user.id`
- `routes.rb`
  - `resources :users, only: %i[new create]`
  - `get "login"`, `post "login"`, `delete "logout"`

## 現行プロジェクトの前提

参照先: `/Users/310tea/Documents/Project/self_reward_app`

### 現状

- Rails 8.0系
- `Gemfile`では`bcrypt`がコメントアウトされている
- `users`テーブル、`User`モデル、認証用Controllerは未作成
- ルートは`root "maps#show"`
- `Goal`がアプリの中心データ
- `Subgoal`は`Goal`に属する
- `TodoItem`は`Subgoal`に属する
- 現在は`Goal.ordered.first_or_create!`で全ユーザー共通のGoal Mapを作っている

### 認証導入時に変えるべき点

ログイン機能だけを追加すると、全ユーザーが同じ`Goal`を見たり編集できてしまう。そのため、セッション機能と同時に`Goal`をユーザー所有にする。

要件上、1ユーザーが持つ`Goal`は1つだけなので、モデルは`has_one :goal`、DBは`goals.user_id`のユニーク制約で保証する。

```text
User
  has_one :goal

Goal
  belongs_to :user
  has_many :subgoals

Subgoal
  belongs_to :goal
  has_many :todo_items

TodoItem
  belongs_to :subgoal
```

`Subgoal`と`TodoItem`には直接`user_id`を持たせず、`goal.user_id`経由で所有者を判定する。

## ルーティング設計

```ruby
Rails.application.routes.draw do
  root "maps#show"

  resources :users, only: %i[new create]

  get "login", to: "user_sessions#new"
  post "login", to: "user_sessions#create"
  delete "logout", to: "user_sessions#destroy"

  resource :map, only: :show

  resources :goals, only: :update do
    resources :subgoals, only: :create
  end

  resources :subgoals, only: %i[create edit update destroy] do
    patch :claim_reward, on: :member
    resources :todo_items, only: :create
  end

  resources :todo_items, only: %i[create edit update] do
    patch :toggle, on: :member
  end

  get "prototype" => "prototype#home"
  get "prototype/onboarding" => "prototype#onboarding"
  get "prototype/today" => "prototype#today"
  get "prototype/rest" => "prototype#rest"
end
```

`prototype/*`はUI確認用の静的プロトタイプなので、認証対象から外してよい。実サービス画面である`maps`, `goals`, `subgoals`, `todo_items`はログイン必須にする。

`User`と`Goal`は1対1だが、現行ビューは`goal_path(goal_record)`や`goal_subgoals_path(goal_record)`を使っている。そのため、初期実装では既存フォームへの影響を抑えるために`resources :goals, only: :update`を維持する。単数ルートに寄せる場合は、フォーム側のURLも`goal_path`相当の単数リソースに合わせて変更する。

## DB設計

### usersテーブル

```ruby
create_table :users do |t|
  t.string :name, null: false
  t.string :email, null: false
  t.string :password_digest, null: false

  t.timestamps
end

add_index :users, :email, unique: true
```

前回プロジェクトには`avatar`と`introduction`があったが、現行アプリの初期セッション機能には不要。プロフィール機能を作る段階で追加する。

### goalsテーブル

```ruby
add_reference :goals, :user, null: false, foreign_key: true
add_index :goals, :user_id, unique: true
```

既存の開発データがある場合は、いきなり`null: false`を付けるとmigrationで失敗する可能性がある。既存Goalを残したい場合は、以下のどちらかで対応する。

- 開発DBをリセットできる場合: `users`作成後に`goals.user_id null: false`を追加
- 既存データを残す場合: `user_id null: true`で追加、既存Goalを仮ユーザーに紐付け、1ユーザーに複数Goalがない状態へ整理してから`unique index`と`change_column_null :goals, :user_id, false`を追加

## モデル設計

### User

```ruby
class User < ApplicationRecord
  has_secure_password

  has_one :goal, dependent: :destroy

  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true,
                    length: { maximum: 255 },
                    uniqueness: true
  validates :password, length: { minimum: 8 }, allow_nil: true
end
```

前回プロジェクトより少し厳しくし、メールの最大文字数とパスワード最小文字数を入れる。

### Goal

```ruby
class Goal < ApplicationRecord
  belongs_to :user

  has_many :subgoals, -> { ordered }, dependent: :destroy, inverse_of: :goal
  has_many :todo_items, through: :subgoals

  validates :user_id, uniqueness: true
  validates :value_statement, presence: true
  validates :title, presence: true

  scope :ordered, -> { order(created_at: :asc, id: :asc) }
end
```

## Controller設計

### ApplicationController

```ruby
class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  helper_method :current_user, :logged_in?
  before_action :require_login
  add_flash_types :success, :warning

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    redirect_to login_path, warning: "ログインが必要です。" unless logged_in?
  end

  def logout
    reset_session
    @current_user = nil
  end
end
```

前回プロジェクトは`session[:user_id] = nil`でログアウトしていたが、ログイン・ログアウトでは`reset_session`を使う方がセッション固定攻撃への耐性が上がる。

### UsersController

```ruby
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
      redirect_to root_path, success: "アカウントを作成しました。"
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
```

前回プロジェクトでは登録後にログイン画面へ遷移していた。現行アプリでは登録直後にマップ作成へ進ませたいので、自動ログインさせる設計にする。

### UserSessionsController

```ruby
class UserSessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create]

  def new; end

  def create
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      reset_session
      session[:user_id] = user.id
      redirect_to root_path, success: "ログインしました。"
    else
      flash.now[:alert] = "メールアドレスまたはパスワードが正しくありません。"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    logout
    redirect_to login_path, status: :see_other, success: "ログアウトしました。"
  end
end
```

## 既存Controllerの変更方針

### MapsController

現在:

```ruby
Goal.ordered.first_or_create!(...)
```

変更後:

```ruby
current_user.goal || current_user.create_goal!(
  title: "目標を設定しましょう",
  value_statement: "今日の一歩が、目指したい未来につながっています。",
  description: "大きな目標、サブゴール、今日のTodoを設定して、道のりを見える形にしましょう。"
)
```

`has_one`では`first_or_create!`ではなく、`current_user.goal || current_user.create_goal!(...)`で初期Goalを作る。

### GoalsController

現在:

```ruby
@goal = Goal.find(params.expect(:id))
```

変更後:

```ruby
@goal = current_user.goal
raise ActiveRecord::RecordNotFound unless @goal&.id == params.expect(:id).to_i
```

他ユーザーのGoal IDを指定されても取得できないようにする。

### SubgoalsController

`Goal.find`と`Subgoal.find`を、必ず`current_user`のGoal配下に限定する。

```ruby
@goal = current_user.goal
raise ActiveRecord::RecordNotFound unless @goal&.id == params.expect(:goal_id).to_i
@subgoal = Subgoal.joins(:goal).where(goals: { user_id: current_user.id }).find(params.expect(:id))
```

`default_goal`も`current_user.goal || current_user.create_goal!(...)`へ変更する。

### TodoItemsController

`Subgoal.find`と`TodoItem.find`を、必ず`current_user`のGoal配下に限定する。

```ruby
@subgoal = Subgoal.joins(:goal).where(goals: { user_id: current_user.id }).find(params.expect(:subgoal_id))
@todo_item = TodoItem.joins(subgoal: :goal).where(goals: { user_id: current_user.id }).find(params.expect(:id))
```

これにより、URLを直接書き換えて他ユーザーのTodoを編集することを防ぐ。

## View設計

### 追加する画面

- `app/views/users/new.html.erb`
  - 名前
  - メールアドレス
  - パスワード
  - パスワード確認
- `app/views/user_sessions/new.html.erb`
  - メールアドレス
  - パスワード

前回プロジェクトのフォーム構成は再利用できるが、現行アプリのトンマナは「ミチシルベ」の暗いマップUIなので、色や余白は`app/assets/stylesheets/application.css`の既存スタイルへ寄せる。

### Layout

`app/views/layouts/application.html.erb`にFlash表示とログイン状態に応じたナビゲーションを追加する。

```erb
<% flash.each do |type, message| %>
  <div class="flash flash-<%= type %>"><%= message %></div>
<% end %>
```

ログイン中:

- マップ
- ログアウト
- `current_user.name`

未ログイン:

- ログイン
- アカウント作成

## 認証対象

ログイン不要:

- `users#new`
- `users#create`
- `user_sessions#new`
- `user_sessions#create`
- `prototype/*`
- `rails/health#show`

ログイン必須:

- `maps#show`
- `goals#update`
- `subgoals#create/edit/update/destroy/claim_reward`
- `todo_items#create/edit/update/toggle`
- `posts`は現状scaffold由来に見えるため、残すならログイン必須にする

## セキュリティ方針

- Deviseは使わない
- パスワードは平文保存しない
- `has_secure_password`で`password_digest`に保存する
- `bcrypt`を有効化する
- ログイン成功時は`reset_session`後に`session[:user_id]`を保存する
- ログアウト時も`reset_session`
- `current_user`配下のデータだけを検索する
- `password`は8文字以上にする
- ログイン失敗時は「メールアドレスまたはパスワードが正しくありません。」に統一し、どちらが誤りかを出さない

## 実装手順

1. `Gemfile`の`bcrypt`コメントアウトを解除して`bundle install`
2. `users`テーブル作成migrationを追加
3. `goals`へ`user_id`を追加するmigrationを追加し、`goals.user_id`に`unique index`を付ける
4. `User`モデルを追加
5. `User`へ`has_one :goal`、`Goal`へ`belongs_to :user`と`validates :user_id, uniqueness: true`を追加
6. `ApplicationController`に`current_user`, `logged_in?`, `require_login`, `logout`を追加
7. `UsersController`を追加
8. `UserSessionsController`を追加
9. `routes.rb`へユーザー登録・ログイン・ログアウトのルートを追加
10. `PrototypeController`とヘルスチェックを認証対象外にする
11. `MapsController`, `GoalsController`, `SubgoalsController`, `TodoItemsController`の検索範囲を`current_user`配下に限定
12. アカウント作成画面とログイン画面を追加
13. LayoutにFlashとナビゲーションを追加
14. Controller test / Model testを追加

## テスト設計

### Model test

- `User`は`name`, `email`, `password`があれば有効
- `email`が重複すると無効
- `password`が8文字未満なら無効
- `authenticate`で正しいパスワードのみ認証できる

### Controller / Integration test

- 未ログインで`root_path`へアクセスすると`login_path`へリダイレクト
- アカウント作成に成功するとログイン状態になり`root_path`へ遷移
- ログインに成功すると`session[:user_id]`が設定される
- ログインに失敗すると`unprocessable_entity`
- ログアウトすると`session[:user_id]`が消える
- ユーザーAはユーザーBのGoalを更新できない
- ユーザーAはユーザーBのSubgoal / TodoItemを編集できない
- 1ユーザーに2つ目のGoalを作れない

## 注意点

現行アプリの中心データはユーザー別でなければ意味がないため、セッション機能だけを入れて`Goal.ordered.first_or_create!`を残す実装は避ける。ログイン後の初回アクセスで`current_user.goal || current_user.create_goal!(...)`を使い、ユーザーごとの初期Goal Mapを1つだけ作る。

前回プロジェクトの実装は最小構成として有効だが、現行アプリへ移す際は以下を改善して実装する。

- 登録後は自動ログイン
- `reset_session`を使う
- `Goal`をユーザー所有にし、1ユーザー1GoalをDB制約でも保証する
- 既存データ取得をすべて`current_user`配下に限定する
