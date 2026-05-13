require "test_helper"

class LandingControllerTest < ActionDispatch::IntegrationTest
  test "shows public landing page when logged out" do
    get root_path

    assert_response :success
    assert_match "今日の学習を、未来まで続く道のりに変える。", response.body
    assert_match "長期学習のためのロードマップアプリ", response.body
    assert_match "lp-concept-band-reference", response.body
    assert_match "頑張っているのに、進んでいる実感が持てない。Todoを増やすより、進んでいる方向を見失わない。", response.body
    assert_match 'href="/users/new"', response.body
    assert_match 'href="/login"', response.body
    assert_match 'id="concept"', response.body
    assert_no_match 'id="usage"', response.body
    assert_no_match 'id="features"', response.body
    assert_no_match "lp-app-preview", response.body
    assert_no_match "lp-map-board", response.body
    assert_no_match "lp-single__column", response.body
    assert_no_match "lp-single__route", response.body
    assert_no_match "使い方は、道のりを置いて、進んだ地点を確認するだけ。", response.body
    assert_no_match "下へスクロールして、使い方を見る", response.body
    assert_no_match 'href="#lp-final-cta"', response.body
    assert_no_match "lp-image-preview", response.body
    assert_no_match "lp-reference-mock.png", response.body
    assert_no_match "クエストは、今日やるTodoではなく", response.body
    assert_no_match "lp-reference", response.body
    assert_no_match "lp-reference-full.png", response.body
  end
end
