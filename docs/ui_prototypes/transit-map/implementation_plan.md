# Transit Map MVP 実装計画

## 実装方針

Rails初学者向けの1ユーザー固定プロトタイプとして実装する。認証、DB永続化、複数ユーザー、複数路線管理はMVPから外す。

今回の最優先制約は「事前に作成したUI画像にピクセルレベルで忠実」であるため、MVPでは生成済みモック画像を各ページのベースビジュアルとして使用する。HTML/CSSで全パーツを再構築するのではなく、画像を主役にし、Rails/Turboによるページ遷移、ホットスポットリンク、軽いアニメーションを重ねる。

これにより、初学者でも画像通りの見た目を保ちながら、MVPの導線を確認できる。

## 対象ページ

| ページ | パス | 画像 |
| --- | --- | --- |
| ホーム / 目標マップ | `/` | `docs/ui_prototypes/transit-map/ui.png` |
| 初期設定 / 路線作成 | `/onboarding` | `docs/ui_prototypes/transit-map/pages/onboarding.png` |
| 今日の一歩 | `/today` | `docs/ui_prototypes/transit-map/pages/today.png` |
| 休憩地点 / ご褒美 | `/rest` | `docs/ui_prototypes/transit-map/pages/rest.png` |

## 技術方針

- Rails routesで4ページを定義する
- `PrototypeController` を追加する
- Tailwind CSSでページフレーム、画像表示、ホットスポット、アニメーションを定義する
- Stimulusでページ表示時のフェードイン、ホットスポットの軽いパルス、キーボード遷移を扱う
- Turboは通常リンク遷移に任せる

## アセット方針

- 生成済みUI画像を `app/assets/images/prototypes/transit-map/` にコピーして使用する
- アイコン単体は今回のMVPでは新規使用しない
- 画面内に見えるアイコンは生成済みUI画像内のものを使用する
- 別アイコンが必要になった場合は、透過PNGとして生成・配置する

## TODO

### TODO 1: Railsルーティングとコントローラ

- `PrototypeController` を作成する
- `home`, `onboarding`, `today`, `rest` アクションを作成する
- rootを `prototype#home` に変更する
- `/onboarding`, `/today`, `/rest` を追加する

### TODO 2: 画像アセット配置

- Transit Mapの4画像を `app/assets/images/prototypes/transit-map/` にコピーする
- Railsの `image_tag` から参照できることを確認する

### TODO 3: 共通レイアウトとページビュー

- アプリ全体の余白をリセットし、プロトタイプ用の全画面レイアウトに変更する
- 4ページのERBビューを作成する
- 各ページで対応するUI画像を画面幅いっぱいに表示する
- 画像のアスペクト比を保ち、デスクトップで余白が出ないようにする

### TODO 4: ホットスポットナビゲーション

- 画像上に透明リンクを重ねる
- ホームから `/onboarding`, `/today`, `/rest` へ移動できるようにする
- 各ページから主要ページへ戻れる導線を作る
- 画像の見た目を邪魔しない

### TODO 5: Stimulusアニメーション

- ページ表示時のフェードイン
- 画像そのものの常時変形やホットスポットの常時表示は避け、モック画像への忠実度を優先する
- キーボードショートカット: `1` ホーム、`2` 初期設定、`3` 今日の一歩、`4` 休憩

### TODO 6: 画面確認

- Railsサーバーを起動する
- Browser Useで各ページを開く
- 画像が非表示、崩れ、余白過多、スクロール破綻していないか確認する
- 必要に応じてCSSを修正する

## 完了基準

- `/`, `/onboarding`, `/today`, `/rest` が表示できる
- 各ページで対応するMVP画像が大きく表示される
- 画像の縦横比が崩れない
- ページ遷移ができる
- フェードインが過剰ではない
- Browser Useでデスクトップ表示を確認済み
