require "test_helper"

class LandingControllerTest < ActionDispatch::IntegrationTest
  test "shows public landing page when logged out" do
    get root_path

    assert_response :success
    assert_match "今日の学習を、未来まで続く道のりに変える。", response.body
    assert_match "長期学習のためのロードマップアプリ", response.body
    assert_match "頑張っているのに、進んでいる実感が持てない。", response.body
    assert_match "使い方は、道のりを置いて、進んだ地点を確認するだけ。", response.body
    assert_match "なぜ、この道を進みたいのか", response.body
    assert_match "できるようになりたい条件を置く", response.body
    assert_match "最初に作るのは、あなた専用の学習マップ。", response.body
    assert_match "以下の5ステップで、あなただけの道のりをつくりましょう。", response.body
    assert_match "最初は仮の内容でも大丈夫。学習しながら、あとで何度でも見直せます。", response.body
    assert_match "まずは、目指す未来と最初の中継地点を置く。", response.body
    assert_match "完璧な計画はいりません。道を置き、確認しながら進めば大丈夫。ミチシルベが、あなたの長い旅を支えます。", response.body
    assert_match 'href="#concept"', response.body
    assert_match 'href="#usage"', response.body
    assert_match 'href="#features"', response.body
    assert_match 'id="concept"', response.body
    assert_match 'id="usage"', response.body
    assert_match 'id="features"', response.body
    assert_match "使い方を見る", response.body
    assert_match "クエスト", response.body
    assert_no_match "クエストは、今日やるTodoではなく", response.body
    assert_no_match "lp-reference", response.body
    assert_no_match "lp-reference-full.png", response.body
  end
end
