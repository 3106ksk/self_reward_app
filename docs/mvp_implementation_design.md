# MVP要件に向けた実装設計

## 目的

`concept_decision_log.md`で整理した現在のMVP要件をもとに、既存プロジェクトで修正が必要な箇所、MVPに不要な機能、新しく追加を検討する機能を整理し、実装に入れる状態まで設計する。

現時点の採用方針は以下。

> サブゴール配下には毎日のTodoではなく、サブゴール達成に必要なクエストを置く。ユーザーは日々の学習を通じてクエストをクリアし、クエストクリア時には小さなご褒美を選べる。全クエストをクリアするとサブゴール達成となり、大きなご褒美を受け取れる。

## 現行実装の状態

現在の主要モデルは以下。

```text
User
  has_one Goal

Goal
  has_many Subgoals
  has_many TodoItems through Subgoals

Subgoal
  has_many TodoItems
  reward_title
  reward_description
  reward_claimed_at

TodoItem
  title
  memo
  completed_at
  position
```

現行実装は、構造としては新MVPに近い。

```text
Goal
  -> Subgoal
      -> TodoItem
```

ただし、`TodoItem`という名称と画面文言が「毎日のTodo」や「今日の一歩」に寄っているため、コンセプトとのズレが出ている。

## 現行実装で活かせる部分

### 1. 認証とユーザー所有

`User has_one Goal`の構造はそのまま使える。

現在のMVPでは、ユーザーごとに1つの長期ゴールを持つ設計で問題ない。

活かす実装:

- `User`
- `UsersController`
- `UserSessionsController`
- `ApplicationController#current_user`
- `Goal belongs_to :user`
- `goals.user_id`のユニーク制約

### 2. Goal

長期ゴールと価値観を扱うモデルとしてそのまま使える。

現行のフィールドもMVP要件に合っている。

```text
goals.title             -> 長期ゴール
goals.value_statement   -> 価値観
goals.description       -> ゴールの説明、理想状態
```

修正は主に文言。

### 3. Subgoal

長期ゴールまでの中継地点としてそのまま使える。

現在の`reward_title` / `reward_description` / `reward_claimed_at`は、サブゴール達成後の大きなご褒美として使える。

ただし、画面上は「ご褒美ポイント」ではなく「サブゴール達成のご褒美」「大きなご褒美」と表現する。

### 4. サブゴール完了判定

現行の`Subgoal#completed?`は、配下の`TodoItem`がすべて完了したらサブゴール完了になる。

このロジックは、新MVPの以下にそのまま対応できる。

```text
全クエストをクリアしたらサブゴール達成
```

`TodoItem`を`Quest`へリネームしても、ロジック自体は活かせる。

## 修正が必要な箇所

### 1. TodoItemをQuestへ変更する

最も重要な修正。

現状の`TodoItem`は、実体としては「サブゴール達成に必要な項目」として使えるが、名前がコンセプトと合っていない。

変更方針:

```text
TodoItem -> Quest
todo_items -> quests
todo_items_controller -> quests_controller
todo_items/_form -> quests/_form
```

画面文言も変更する。

| 現在 | 変更後 |
| --- | --- |
| TodoItem | Quest |
| Todo | クエスト |
| 今日やったこと | クエスト名、達成条件 |
| 一歩を追加 | クエストを追加 |
| 完了タスク | クリア済みクエスト |
| 完了にする | クエストをクリア |
| つながるサブ目標 | 対象のサブゴール |

### 2. 「毎日のTodo」を連想させる文言を消す

以下の文言はMVPコンセプトとズレる。

- 今日の一歩を記録
- 今日やったこと
- 今日のTodo
- 完了タスク
- Todo item was successfully...
- このサブゴールと紐づくTodoを削除します

変更後の方向性:

- クエストを追加
- サブゴール達成に必要なクエスト
- クエストをクリア
- クリア済みクエスト
- サブゴールと紐づくクエストを削除します

### 3. デフォルト文言を変える

現在のデフォルトGoal説明に「今日のTodo」が含まれている。

変更前:

```text
大きな目標、サブゴール、今日のTodoを設定して、道のりを見える形にしましょう。
```

変更後:

```text
大きな目標、サブゴール、クエストを設定して、道のりを見える形にしましょう。
```

### 4. サブゴールとクエストの「順番」入力をフォームから外す

現行フォームでは、サブゴール作成時に`position`を「順番」として数字入力させている。

しかし、現在の実装では`position`はユーザー向けの並び替え機能ではなく、内部の並び順キーである。

そのため、ユーザーは以下のように期待しやすい。

```text
「順番」に2を入れる
  -> 2番目に表示される
  -> 既存の2番目以降は自動で後ろにずれる
```

一方で、現行実装は以下に近い。

```text
入力されたpositionをそのまま保存する
  -> 同じpositionが複数できる可能性がある
  -> 既存データの並び順は自動調整されない
  -> ユーザーの期待した順番にならないことがある
```

これは「使い方が分かりづらい」のではなく、UIが実装の都合をユーザーに見せてしまっている状態。

MVPでは、`position`はフォームから外し、作成時に末尾へ自動追加する。

```text
新しいサブゴール -> 最後に追加
新しいクエスト -> 対象サブゴール内の最後に追加
```

並び替えを提供する場合は、数字入力ではなく専用の操作にする。

候補:

- 上へ移動 / 下へ移動ボタン
- ドラッグ&ドロップ
- 「このサブゴールの前に移動」などのメニュー

ただし、MVPでは並び替え機能は実装しない。

上へ移動 / 下へ移動ボタンやドラッグ&ドロップは、MVP後の拡張候補とする。

実装方針:

- `position`カラムは内部用として残す
- `SubgoalsController#create`では常に`next_position(@goal.subgoals)`を設定する
- `QuestsController#create`でも常に`next_position(@subgoal.quests)`を設定する
- `position`はstrong parametersから外す
- `position`のフォーム入力欄を削除する
- 編集フォームでも`position`を直接編集させない

### 5. Posts scaffoldをMVP対象外にする

`posts`は現在のMVP要件に関係しない。

存在するもの:

- `Post`モデル
- `PostsController`
- `posts` routes
- `posts` views
- `posts` tests
- `posts` table

MVPの焦点を濁らせるため、実装段階では削除候補。

ただし、削除はDB migrationを伴うため、作業順としては`Quest`化と報酬設計が終わった後に行う。

### 6. Prototype画面は本番MVPから切り離す

`prototype/*`はUI検討用として価値があるが、MVPの実サービス導線ではない。

方針:

- 開発用ルートとして残してよい
- 本番導線やテスト要件には含めない
- 実装の優先度は低い

## 現在のMVPに必要ない機能

### 1. ゴールド経済

現時点では実装しない。

理由:

- 学習時間を稼ぐ体験に寄る
- ロードマップアプリではなくご褒美交換アプリに戻る
- MVPで検証したい価値がぼやける

今回のMVPでは、報酬は以下に限定する。

- クエストクリア時の小さなご褒美
- サブゴール達成時の大きなご褒美

### 2. 毎日の学習Todo

実装しない。

理由:

- 毎日Todoを作る負担が増える
- Todoアプリとの差別化が弱くなる
- 未完了タスクが焦りにつながる

日々の学習は、直接DBで日次Todoとして管理せず、クエストクリアの行動として扱う。

### 3. 学習時間記録

現時点では主機能にしない。

将来的には学習ログとして検討できるが、MVPでは以下を優先する。

- クエストが見える
- クエストをクリアできる
- 小さなご褒美を選べる
- サブゴール達成で大きなご褒美を受け取れる

### 4. 連続日数、ランキング、競争

実装しない。

想定ユーザーは焦りや比較で疲れやすいため、競争や連続記録の強調はコンセプトと相性が悪い。

## 新しく追加を検討する機能

### 1. 小さなご褒美リスト

クエストクリア時に選ぶための小さなご褒美を管理する。

小さなご褒美は、Goal配下に作成される「ご褒美リスト」として扱う。

MVPでは、Todoリストのご褒美版のような軽い実装でよい。

```text
小さなご褒美リスト
- 好きなドリンクを飲む
- 30分だけ動画を見る
- 散歩する
- PCを閉じて休む
```

ユーザーが小さなご褒美を作成すると、このリストに追加される。

クエストクリア時には、このリストから1つ選び、選んだご褒美をQuestに紐づける。

新規モデル候補:

```text
SmallReward
  belongs_to :goal

  title:string, null: false
```

MVPでは、ご褒美名だけを管理する。

以下は実装しない。

- メモ
- 表示順
- 有効/無効

理由は、MVPで検証したい価値が「小さなご褒美を細かく管理できるか」ではなく、「クエストクリア時に小さなご褒美を選べることが前進感や継続意欲につながるか」だから。

`User`ではなく`Goal`に紐づける理由:

- 現在の設計では1ユーザー1ゴール
- Goal配下に学習ロードマップのデータを集約できる
- 所有者判定は`goal.user_id`経由でできる

### 2. Questに選択済み小さなご褒美を持たせる

クエストをクリアした時に、小さなご褒美を1つ選べるようにする。

`quests`に追加する候補:

```text
small_reward_id:bigint, null: true
small_reward_claimed_at:datetime, null: true
```

意味:

- `small_reward_id`: クエストクリア時に選んだ小さなご褒美
- `small_reward_claimed_at`: 小さなご褒美を受け取った日時

クエストが未クリアに戻された場合の扱い:

- MVPでは`completed_at`をnilに戻したら、`small_reward_id`と`small_reward_claimed_at`もnilに戻す
- 履歴を残す設計は後回し

### 3. クエストクリア時のご褒美選択UI

理想の流れ:

```text
クエスト一覧で「クリア」を押す
  -> 小さなご褒美リストが表示される
  -> リストからご褒美を1つ選んでチェックする
  -> クエストがクリア済みになる
  -> マップ上でクリア済みクエストとして表示される
```

MVPでは、実装を簡単にするため以下でもよい。

```text
クエスト編集フォームに「小さなご褒美」セレクトを置く
  -> 「クエストをクリア」を押す
  -> completed_at / small_reward_id / small_reward_claimed_at を同時に保存
```

画面イメージ:

```text
クエスト:
CRUDアプリを1つ作る

[クリアする]

小さなご褒美を選ぶ:
□ 好きなドリンクを飲む
□ 30分だけ動画を見る
□ 散歩する

[このご褒美を受け取る]
```

### 4. 小さなご褒美の初期値

ユーザーが最初から試しやすいように、Goal作成時に小さなご褒美候補を数件作ることを検討する。

例:

- 好きなドリンクを飲む
- 30分だけ好きな動画を見る
- 散歩する
- 早めにPCを閉じる

ただし、自分で設定する体験も重要なので、初期値は多すぎない方がよい。

## 推奨データモデル

### 最小構成

```text
User
  has_one Goal

Goal
  belongs_to User
  has_many Subgoals
  has_many SmallRewards

Subgoal
  belongs_to Goal
  has_many Quests
  big_reward_title
  big_reward_description
  big_reward_claimed_at

Quest
  belongs_to Subgoal
  belongs_to SmallReward, optional: true
  title
  description
  completed_at
  small_reward_claimed_at
  position

SmallReward
  belongs_to Goal
  has_many Quests
  title
```

### 実装時の現実的なDB変更

既存データを活かすなら、以下の順番が安全。

1. `todo_items`を`quests`へrename
2. `quests.memo`を`description`へrenameするか、当面は`memo`のまま表示名だけ変える
3. `small_rewards`テーブルを追加
4. `quests.small_reward_id`を追加
5. `quests.small_reward_claimed_at`を追加
6. 必要なら`subgoals.reward_title`を`big_reward_title`へrename
7. 必要なら`subgoals.reward_description`を`big_reward_description`へrename
8. 必要なら`subgoals.reward_claimed_at`を`big_reward_claimed_at`へrename

MVP実装の速度を優先するなら、`subgoals.reward_*`はDB名をそのまま残し、画面文言だけ「大きなご褒美」に変える。

## 推奨ルーティング

変更前:

```ruby
resources :subgoals, only: %i[create edit update destroy] do
  patch :claim_reward, on: :member
  resources :todo_items, only: :create
end

resources :todo_items, only: %i[create edit update] do
  patch :toggle, on: :member
end
```

変更後:

```ruby
resources :subgoals, only: %i[create edit update destroy] do
  patch :claim_reward, on: :member
  resources :quests, only: :create
end

resources :quests, only: %i[create edit update] do
  patch :complete, on: :member
  patch :uncomplete, on: :member
end

resources :small_rewards, only: %i[create edit update]
```

`toggle`より`complete` / `uncomplete`を分ける理由:

- クエストクリア時に小さなご褒美選択が必要になる
- クリアと取り消しで副作用が違う
- 実装とテストが読みやすくなる

## 画面設計

### サイドパネル

現在:

```text
価値観設定
目標設定
サブゴールを追加
今日の一歩を記録
```

変更後:

```text
価値観設定
長期ゴール設定
サブゴール設定
クエスト設定
小さなご褒美設定
```

### マップ表示

サブゴールノード内に表示するもの:

- 未クリアクエストの一部
- クリア済みクエストの一部
- サブゴール達成状態
- 大きなご褒美の状態

文言:

```text
未クリアクエスト
クリア済みクエスト
大きなご褒美
獲得可
獲得済み
```

### クエストフォーム

入力項目:

- クエスト名
- 説明、メモ
- 対象サブゴール

フォームには`position`を出さない。

クエストは作成時に対象サブゴール内の末尾へ自動追加する。

編集時:

- クリア状態
- 小さなご褒美選択

### 小さなご褒美フォーム

入力項目:

- ご褒美名

MVPでは以下は入力させない。

- メモ
- 表示順
- 有効/無効

小さなご褒美は「報酬マスタ管理」ではなく、クエストクリア時に選ぶ軽い選択肢として扱う。

作成後は、Goal配下の小さなご褒美リストに追加される。

```text
小さなご褒美を追加
[ ご褒美名 ]
[ 追加 ]

小さなご褒美リスト
- 好きなドリンクを飲む
- 30分だけ動画を見る
- 散歩する
```

## 実装順序

### Phase 1: 用語と責務の修正

目的は、既存実装を新コンセプトに合わせること。

作業:

- `TodoItem`を`Quest`へrename
- `todo_items`を`quests`へrename
- controller / view / route / testの名称を更新
- 画面文言からTodo、今日の一歩を削除
- デフォルトGoal説明を修正
- サブゴールとクエストの`position`入力欄をフォームから削除
- 作成時の`position`はController側で末尾に自動設定
- `position`をstrong parametersから外す
- seedsをクエスト表現へ変更

この段階では、小さなご褒美はまだ追加しない。

### Phase 2: 小さなご褒美リストを追加

作業:

- `SmallReward`モデル追加
- `small_rewards`テーブル追加
- `Goal has_many :small_rewards`
- `SmallRewardsController`追加
- サイドパネルに小さなご褒美フォームを追加
- 小さなご褒美フォームは`title`だけにする
- 作成した小さなご褒美をGoal配下のリストとして表示する
- 所有者チェックを`current_user.goal.small_rewards`経由で行う

### Phase 3: クエストクリア時の小さなご褒美選択

作業:

- `quests.small_reward_id`追加
- `quests.small_reward_claimed_at`追加
- `Quest belongs_to :small_reward, optional: true`
- `QuestsController#complete`を追加
- クリア時に小さなご褒美を選べるようにする
- 未クリアに戻す場合は小さなご褒美選択をクリアする

### Phase 4: サブゴール達成と大きなご褒美の整理

作業:

- `Subgoal#completed?`を`quests`基準に更新
- `Subgoal#reward_available?`を大きなご褒美の文脈に合わせる
- 画面文言を「大きなご褒美」に統一
- 必要ならDBカラム名を`big_reward_*`へrename

### Phase 5: 不要機能の削除

作業:

- `posts` routesを削除
- `Post`モデル、Controller、views、testsを削除
- `posts` tableのdrop migrationを追加
- 未使用のhelperやfixtureを削除

この作業は、主要機能の変更が安定してから行う。

## テスト方針

### Model test

追加・更新するテスト:

- GoalがSmallRewardを持てる
- SubgoalがQuestを持てる
- Questはtitleとpositionが必須
- Questはcompleted_atでクリア判定する
- Questクリア時にSmallRewardを紐づけられる
- Subgoalは全Questクリアでcompletedになる
- Subgoal達成後に大きなご褒美が獲得可能になる

### Controller test

追加・更新するテスト:

- Questを作成できる
- Questを編集できる
- Questをクリアできる
- Questクリア時にSmallRewardを選択できる
- Quest未クリアに戻すとSmallReward選択が解除される
- 他ユーザーのQuestを操作できない
- SmallRewardを作成、編集できる
- 他ユーザーのSmallRewardを操作できない
- 全Questクリア後にSubgoalの大きなご褒美を受け取れる

### View / integration test

確認する表示:

- Todoという文言が実サービス画面に出ない
- 今日の一歩という文言が実サービス画面に出ない
- サブゴールフォームとクエストフォームに順番入力が出ない
- クエスト、クリア済みクエスト、小さなご褒美、大きなご褒美が表示される
- サブゴール完了前は大きなご褒美を獲得できない
- サブゴール完了後は大きなご褒美を獲得できる

## 実装時の注意点

### 1. 名前変更は大きいので段階的に行う

`TodoItem`から`Quest`への変更は、モデル、Controller、View、Route、Test、CSS class、Stimulus targetに影響する。

一度に小さなご褒美まで追加すると差分が大きくなるため、まずは用語と責務の変更を完了させる。

### 2. DBカラム名は無理に全部変えなくてよい

MVPの速度を優先するなら、`subgoals.reward_*`は当面そのまま使ってよい。

ただし、コード上のメソッド名や画面文言では「大きなご褒美」として扱う。

### 3. 小さなご褒美は履歴管理しない

MVPでは、クエストに選択済みご褒美を1つ持たせるだけにする。

将来的に「いつ、どのご褒美を受け取ったか」の履歴を見せたくなったら、`reward_claims`のような別モデルを検討する。

### 4. 未完了圧を強くしない

クエストは達成条件だが、表示上は「未完了が残っている」という圧を強くしない。

避ける表現:

- 残りタスク
- 未消化
- 遅れ
- 達成率を大きく出す

使う表現:

- 次に進めるクエスト
- クリア済みクエスト
- チェックポイントに近づいています

## 最終的なMVPスコープ

### 必須

- アカウント作成、ログイン、ログアウト
- 価値観設定
- 長期ゴール設定
- サブゴール作成、編集、削除
- クエスト作成、編集、クリア
- 小さなご褒美作成、編集
- クエストクリア時の小さなご褒美選択
- 全クエストクリアによるサブゴール達成判定
- サブゴール達成後の大きなご褒美獲得
- マップ上でゴール、サブゴール、クエスト、報酬状態を確認

### 任意

- サブゴール最大数の制限
- 小さなご褒美の初期候補作成

### 今はやらない

- ゴールド
- 学習時間記録
- 毎日のTodo作成
- 小さなご褒美のメモ
- 小さなご褒美の表示順変更
- 小さなご褒美の有効/無効
- サブゴールの並び替え
- クエストの並び替え
- 連続学習日数
- ランキング
- SNS共有
- 報酬履歴の詳細管理
- 複数Goal対応

### MVP後の拡張候補

- サブゴールの上へ移動 / 下へ移動
- クエストの上へ移動 / 下へ移動
- サブゴールのドラッグ&ドロップ並び替え
- クエストのドラッグ&ドロップ並び替え
- 小さなご褒美のメモ
- 小さなご褒美の表示順変更
- 小さなご褒美の有効/無効

## 実装判断の結論

現行実装は、構造としては大きく間違っていない。

主な問題は、`TodoItem`という概念と画面文言が、日次Todo管理アプリに見せてしまっていること。

そのため、最初に行うべき実装は、機能追加ではなく以下。

1. `TodoItem`を`Quest`へ再定義する
2. 画面文言をクエスト中心に変える
3. サブゴール報酬を「大きなご褒美」として整理する
4. その後、小さなご褒美リストとクエストクリア報酬を追加する

この順番なら、長期学習ロードマップというコンセプトを保ったまま、報酬機能をMVPの価値検証に組み込める。
