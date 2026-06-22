---
paths:
  - "spec/**/*"
---

## テスト実行規約

### フレームワーク方針

- **テストフレームワークは RSpec のみ**。
- テストは必ずコンテナ経由で実行する（ローカル Ruby は使わない）。
- VSCode では `.vscode/tasks.json` に RSpec タスクが定義済み。

---

## RSpec

- 実行コマンド: `docker compose exec notification-api bundle exec rspec`
- ファイル配置:
  - モデル: `spec/models/`
  - サービス: `spec/services/<namespace>/`
  - リクエスト（コントローラ相当）: `spec/requests/api/v1/`
  - ファクトリ: `spec/factories/`
- データ生成は FactoryBot（`spec/factories/*.rb`）。fixtures は使わない。
- DB クリーンアップは `use_transactional_fixtures = true`（各テスト後にロールバック）で管理。
- `ENV['RAILS_ENV'] = 'test'` を強制設定済み（コンテナ内の `RAILS_ENV=development` を上書き）。
- `spec/rails_helper.rb` に以下を include 済み。新規 spec では追加不要:
  - `FactoryBot::Syntax::Methods`（`create` / `build` をそのまま使える）
  - `ActiveJob::TestHelper`（`have_enqueued_job` / `perform_enqueued_jobs` を使う場合）

### WebMock

外部 HTTP 通信は WebMock でスタブする。`require 'webmock/rspec'` は `rails_helper.rb` に設定済みで、**テスト中は実 HTTP 接続が無効**になる。

```ruby
# 外部サービス呼び出しを含むテストでは必ず stub_request を書く
before do
  stub_request(:post, "http://localhost:3001/api/v1/notifications")
    .to_return(status: 201, body: { notification: { id: 1 } }.to_json)
end
```

### RSpec の type 別メモ

| type | 配置先 | 用途 |
|---|---|---|
| `:request` | `spec/requests/` | API エンドポイントの統合テスト |
| `:model` | `spec/models/` | バリデーション・スコープ・アソシエーション |
| `:service` または `type: nil` | `spec/services/` | Service Object の単体テスト |

### リクエスト spec の認証ヘッダー

`authenticate_service!` が全エンドポイントにかかるため、リクエスト spec では必ず認証ヘッダーを付与する。

```ruby
let(:headers) do
  {
    "Authorization" => "Bearer dev-secret",
    "Content-Type"  => "application/json"
  }
end
```

### DB 環境ミスマッチが発生した場合

rspec 起動時に `ActiveRecord::EnvironmentMismatchError` が出たら以下を実行する。

```bash
docker compose exec notification-api bin/rails db:environment:set RAILS_ENV=test
```
