# LP 実装計画書

## 目的

事前生成したLPモック画像を参照し、既存Railsプロジェクトに公開LPを追加する。

対象モック:

`/Users/310tea/.codex/generated_images/019e1a96-d286-7fc3-846f-d0b0475b7e8a/ig_087792e4ab5b2800016a02dd45379c81919a9ab22e218e1ba3.png`

## 実装範囲

モックに含まれる以下の範囲までを実装する。

1. Hero
2. Problem / Concept
3. Usage roadmap
4. Initial setup 5 steps
5. Final CTA

以下は今回実装しない。

- 「クエストは、今日やるTodoではなく...」以降の詳細解説
- 日々の使い方詳細
- ご褒美詳細
- マップの読み方詳細

## ルーティング方針

- 未ログイン時の `root_path` はLPを表示する
- ログイン後のマップ画面は `map_path` で表示する
- ログイン成功、アカウント作成成功後は `map_path` へ遷移する
- ヘッダーの「マップ」はログイン済みの場合 `map_path` に向ける

## 実装方針の修正

参照画像をそのまま `<img>` として貼り付ける実装は禁止する。

LPはRails view + Tailwind/CSSで構成し、参照画像を分解した背景素材・装飾素材のみ画像として使用する。テキスト、ボタン、ナビゲーション、カード、マップUI、ステップUIはHTML/CSSで再現する。

### ピクセル忠実度の基準

- 参照画像のセクション順と高さ比率を合わせる
- 参照画像の余白、横幅、暗背景、境界線、発光感を合わせる
- ナビ、ヒーロー、右側アプリプレビュー、課題/コンセプト帯、使い方アイコン列、5ステップ、最終CTAをHTML/CSSで再現する
- 画像素材は背景・地形・質感・コンパスなどに限定する
- リンク領域だけ透明ホットスポットにする実装は禁止する

## 追加ファイル

- `app/controllers/landing_controller.rb`
- `app/views/landing/index.html.erb`
- `app/assets/images/landing/hero-road.png`
- `app/assets/images/landing/cta-road.png`
- `app/assets/images/landing/compass-mark.png`
- `app/assets/images/landing/map-scene.png`

## 変更ファイル

- `config/routes.rb`
- `app/controllers/user_sessions_controller.rb`
- `app/controllers/users_controller.rb`
- `app/views/layouts/application.html.erb`
- `app/assets/stylesheets/application.css`
- controller tests where root redirect assumptions change

## デザイン再現方針

### 基本サイズ

モックは横幅1440px想定。LP内の主要コンテナは `max-width: 1320px` を基準にする。

### 色

`docs/lp_tone_palette_design.md` のLPパレットをCSS変数として使用する。

### 背景画像

モックの山道・夜明け前のロードマップ表現は、image-genで生成した背景素材を使用する。

- Hero: 山道と遠景を含む暗い背景
- Final CTA: 山道が手前から奥へ伸びる背景

### アイコン

主要な丸アイコンは、CSS円形とシンプルなインラインSVGで再現する。

ロゴのコンパスマークのみ、image-gen生成素材を透過PNGとして使用する。

### アニメーション

以下を付与する。

- Heroロードマップのルート線がゆっくり点灯
- マーカーが軽くパルス
- スクロール進入時にセクションがフェードアップ
- CTAボタン hover で軽く浮く
- 使い方ロードマップの矢印が控えめに流れる

`prefers-reduced-motion: reduce` では停止する。

## 品質基準

- モックのセクション順、色、余白、コピー、視線誘導が一致している
- 日本語コピーが崩れない
- モバイルで横スクロールしない
- ログイン導線と既存マップ導線が壊れない
- 既存テストが通る、または変更理由に沿って更新されている
- Browser UseでLPを表示し、ファーストビューと全体スクロールを確認する

## TODO

- [x] reference mockをプロジェクト内の参照用画像として保存する
- [ ] image-genでHero背景素材を参照画像ベースで再生成して `app/assets/images/landing/hero-road.png` に配置する
- [ ] image-genでアプリプレビュー内の山岳マップ背景を参照画像ベースで生成して `app/assets/images/landing/map-scene.png` に配置する
- [ ] image-genでFinal CTA背景素材を参照画像ベースで再生成して `app/assets/images/landing/cta-road.png` に配置する
- [ ] image-genで透過コンパスマークを参照画像ベースで生成して `app/assets/images/landing/compass-mark.png` に配置する
- [x] `LandingController#index` を追加する
- [x] rootをLPへ変更し、`map_path` をログイン後アプリ画面にする
- [x] ログイン/アカウント作成後の遷移先を `map_path` にする
- [x] layoutのナビゲーションをLP/アプリ両方で破綻しないよう調整する
- [ ] 参照画像貼り付け実装を撤去する
- [ ] LP viewをモックのセクション順でHTMLとして再構築する
- [ ] Tailwind/CSSでレイアウト、背景、マッププレビュー、使い方アイコン列、ステップUIを参照画像に合わせる
- [ ] アニメーションと `prefers-reduced-motion` 対応を追加する
- [x] controller testsを新しいroot仕様に合わせて更新する
- [x] Rails testsを実行する
- [x] Browser Useで `localhost` のLPを開いてスクリーンショット確認する
- [x] 視覚差分を見て余白、色、サイズ、コピーを修正する
