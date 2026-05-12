# Todo追加フォームのサブゴール選択肢更新 修正設計書

## 目的

`self_reward_app`のマップ画面で、サブゴール追加後に「今日の一歩を記録」フォームの「つながるサブ目標」セレクトボックスへ追加済みサブゴールが表示されない不具合を修正する。

この修正では、ユーザーセッション機能の設計で導入したユーザー所有制約を維持しながら、Turbo Stream更新後の画面状態を実データと一致させる。

## 現象

ログイン済みユーザーがマップ画面でサブゴールを追加したあと、画面右側のマップにはサブゴールが表示される。一方、左側パネルの「今日の一歩を記録」フォームにある`select#todo-subgoal-select`は空のままで、追加したサブゴールを選択できない。

該当フォーム:

- `app/views/todo_items/_form.html.erb`
- `select#todo-subgoal-select`

## 原因

`todo_items/_form.html.erb`では、Todo追加先の候補を`goal_record.subgoals`から描画している。

```erb
subgoals = Array(goal_record&.try(:subgoals)).select { |subgoal| subgoal.try(:persisted?) }
```

しかし、`SubgoalsController#create`成功時のTurbo Stream更新では、現在以下のみをreplaceしている。

- `goal-map-board`
- `subgoal_form`

`todo_item_form`は更新対象に含まれていない。そのため、初期表示時にサブゴールが0件だった場合、空のセレクトボックスを含む古い`todo_item_form` DOMが残り続ける。

## 修正方針

サブゴールの作成・更新・削除・ご褒美獲得後に、`todo_item_form`もTurbo Streamで再描画する。

特にサブゴールの作成・更新・削除は、Todo追加フォームの選択肢に直接影響するため、`goal-map-board`と`subgoal_form`だけでなく`todo_item_form`も同じレスポンスで更新する。

## 対象範囲

### 変更するファイル

- `app/controllers/subgoals_controller.rb`
- `test/controllers/maps_controller_test.rb`

### 原則変更しないファイル

- DB migration
- `User`, `Goal`, `Subgoal`, `TodoItem`モデル
- ルーティング
- 認証処理
- `todo_items_controller.rb`の所有者制限

## Controller設計

`SubgoalsController#render_goal_map_stream`で返すTurbo Streamに、`todo_item_form`のreplaceを追加する。

想定する更新対象:

```ruby
turbo_stream.replace("todo_item_form", helpers.turbo_frame_tag("todo_item_form", data: { action: "turbo:frame-render->goal-map#openPanelSection" }) {
  render_to_string(
    partial: "todo_items/form",
    formats: [ :html ],
    locals: { todo_item: @todo_item, map: @map, goal: @goal }
  )
})
```

`load_goal_map`では既に`@todo_item = TodoItem.new(position: 1)`を用意しているため、追加のインスタンス変数は不要。

## View設計

`app/views/todo_items/_form.html.erb`の選択肢生成ロジックは維持する。

理由:

- `goal_record.subgoals`から選択肢を作る設計自体は正しい
- 所有者制限はController側で`current_user.goal`配下に限定されている
- 不具合の本質はViewの条件ではなく、Turbo StreamでViewが再描画されないこと

必要に応じて、将来の改善としてサブゴールが0件の場合の明示的なプレースホルダー表示は検討できる。ただし、この修正では仕様を追加しない。

## セキュリティ方針

この修正で他ユーザーのデータ参照範囲を広げない。

- `SubgoalsController`は引き続き`current_user.goal`配下のデータだけを扱う
- `todo_item_form`に渡す`goal`は`@goal`、つまりログインユーザーのGoalに限定する
- `TodoItemsController`の`owned_subgoals`によるサーバー側検証は維持する

画面上のセレクトボックスに他ユーザーのサブゴールが混ざってはならない。

## テスト設計

### Controller test

`test/controllers/maps_controller_test.rb`に、サブゴール作成後のTurbo Streamレスポンスで`todo_item_form`が更新されることを追加確認する。

確認内容:

- ログイン済みユーザーで`goal_subgoals_path(@goal)`へTurbo Streamリクエストする
- レスポンスに`turbo-frame id="todo_item_form"`が含まれる
- レスポンスに追加したサブゴール名が含まれる
- 他ユーザーのサブゴール名は含まれない

### 既存テスト

既存の以下の確認は維持する。

- サブゴール作成が成功する
- 他ユーザーのSubgoalを操作できない
- TodoItem作成時に他ユーザーのSubgoalへ紐付けできない

## Browser Use確認

修正後、Browser Useで以下を確認する。

1. ログイン済みでマップ画面を開く
2. 「サブゴールを追加」からサブゴールを作成する
3. 「今日の一歩を記録」を開く
4. 「つながるサブ目標」のセレクトボックスに作成したサブゴールが表示される
5. そのサブゴールを選んだ状態でTodoを追加できる

## 完了条件

- サブゴール追加後、ページ全体をリロードしなくてもTodo追加フォームのセレクトボックスにサブゴールが表示される
- サブゴール名を更新した場合、Todo追加フォームの選択肢にも更新後の名前が表示される
- サブゴール削除後、Todo追加フォームの選択肢から削除済みサブゴールが消える
- 他ユーザーのサブゴールは選択肢に表示されない
- Railsテストが通る
- Browser Useで主要フローを確認済み
