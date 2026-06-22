# rails-sandbox-notification-service

Rails 8.1 API-only + PostgreSQL の通知マイクロサービス。
`rails-sandbox-backend` から Bearer Token 認証付きの HTTP リクエストで通知を受け取り、保存・配信する。

## 構成

| 項目 | 内容 |
|---|---|
| Ruby | 3.4.9 |
| Rails | 8.1（API-only） |
| DB | PostgreSQL 16 |
| API ポート | 3001 |
| DB ポート（ホスト） | 5433 |

## セットアップ

### 1. 環境変数ファイルを準備する

```bash
cp .env.example .env
# .env を編集して各値を設定する（開発環境はデフォルト値のままで動作する）
```

### 2. コンテナを起動する

```bash
docker compose up -d
```

起動時に `dev-entrypoint` が自動で以下を実行する:
- `bundle install`
- `bin/rails db:prepare`（DB 作成 + マイグレーション）

### 3. 動作確認

```bash
curl -s -X POST http://localhost:3001/api/v1/notifications \
  -H "Authorization: Bearer dev-secret" \
  -H "Content-Type: application/json" \
  -d '{"article_id": 1, "message": "テスト通知", "user_id": 1}' | jq .
# => { "notification": { "id": 1, "message": "テスト通知", ... } }
```

## 開発コマンド

```bash
# ログ確認
docker compose logs -f notification-api

# Rails コンソール
docker compose exec notification-api bin/rails console

# マイグレーション
docker compose exec notification-api bin/rails db:migrate

# ロールバック
docker compose exec notification-api bin/rails db:rollback

# ルーティング確認
docker compose exec notification-api bin/rails routes

# テスト実行
docker compose exec notification-api bundle exec rspec

# RuboCop（静的解析）
docker compose exec notification-api bundle exec rubocop
```

## API エンドポイント

全エンドポイントで `Authorization: Bearer <INTER_SERVICE_SECRET>` ヘッダーが必須。

### POST /api/v1/notifications

通知を作成する。

**リクエスト**

```json
{
  "article_id": 1,
  "message": "user@example.com さんが「タイトル」を作成しました",
  "user_id": 42
}
```

**レスポンス（201 Created）**

```json
{
  "notification": {
    "id": 1,
    "article_id": 1,
    "message": "user@example.com さんが「タイトル」を作成しました",
    "user_id": 42,
    "read": false,
    "created_at": "2026-06-22T00:00:00.000Z",
    "updated_at": "2026-06-22T00:00:00.000Z"
  }
}
```

**エラーレスポンス**

| ステータス | 原因 |
|---|---|
| 401 Unauthorized | Authorization ヘッダーが不正 |
| 422 Unprocessable Entity | バリデーションエラー |

### GET /api/v1/notifications

指定ユーザーの未読通知一覧を返す。

**クエリパラメータ**

| パラメータ | 必須 | 説明 |
|---|---|---|
| `user_id` | ○ | 取得対象のユーザー ID |

**レスポンス（200 OK）**

```json
{
  "notifications": [
    {
      "id": 1,
      "article_id": 1,
      "message": "...",
      "user_id": 42,
      "read": false,
      "created_at": "2026-06-22T00:00:00.000Z",
      "updated_at": "2026-06-22T00:00:00.000Z"
    }
  ]
}
```

## 認証

`INTER_SERVICE_SECRET` 環境変数に設定したトークンを Bearer Token として使用する。
backend 側の `INTER_SERVICE_SECRET` と同じ値を設定すること。

```bash
# リクエスト例
curl -H "Authorization: Bearer dev-secret" http://localhost:3001/api/v1/notifications?user_id=1
```

## 環境変数

`.env.example` を参照。

| 変数名 | 説明 |
|---|---|
| `POSTGRES_USER` | PostgreSQL ユーザー名 |
| `POSTGRES_PASSWORD` | PostgreSQL パスワード |
| `POSTGRES_DB` | PostgreSQL データベース名 |
| `DATABASE_URL` | Rails の DB 接続 URL |
| `INTER_SERVICE_SECRET` | サービス間認証トークン |

## 他サービスとの連携

```
rails-sandbox-backend (localhost:8080)
  └─ ArticleNotificationJob#perform
       └─ NotificationClient.notify
            └─ POST http://localhost:3001/api/v1/notifications
                 └─ rails-sandbox-notification-service (localhost:3001)
```

backend の `NotificationClient` は `NOTIFICATION_SERVICE_URL` 環境変数（デフォルト: `http://localhost:3001`）と `INTER_SERVICE_SECRET` を参照する。
