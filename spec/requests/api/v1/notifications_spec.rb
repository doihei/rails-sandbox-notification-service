require "rails_helper"

RSpec.describe "Api::V1::Notifications", type: :request do
  let(:headers) do
    {
      "Authorization" => "Bearer #{ENV.fetch('INTER_SERVICE_SECRET')}",
      "Content-Type"  => "application/json"
    }
  end

  describe "POST /api/v1/notifications" do
    context "正常系" do
      it "通知を作成して201を返す" do
        post "/api/v1/notifications",
          params: { article_id: 1, message: "記事が作成されました", user_id: 1 }.to_json,
          headers: headers

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)["notification"]["message"]).to eq("記事が作成されました")
      end
    end

    context "認証エラー" do
      it "シークレットが不正なら401を返す" do
        post "/api/v1/notifications",
          params: { article_id: 1, message: "test", user_id: 1 }.to_json,
          headers: headers.merge("Authorization" => "Bearer wrong-secret")

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/notifications" do
    before do
      Notification.create!(article_id: 1, message: "通知1", user_id: 42)
      Notification.create!(article_id: 2, message: "通知2", user_id: 42, read: true)
    end

    it "未読通知のみ返す" do
      get "/api/v1/notifications",
        params: { user_id: 42 },
        headers: headers

      notifications = JSON.parse(response.body)["notifications"]
      expect(notifications.length).to eq(1)
      expect(notifications.first["message"]).to eq("通知1")
    end
  end
end
