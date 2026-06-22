---
paths:
  - "app/controllers/**/*.rb"
  - "spec/requests/**/*.rb"
  - "config/routes.rb"
---

## REST API の実装規約

### 認証

全エンドポイントは `before_action :authenticate_service!` を必須とする。
`authenticate_service!` は `ApplicationController` に定義されており、
`Authorization: Bearer <token>` ヘッダーを `INTER_SERVICE_SECRET` 環境変数と照合する。

```ruby
# ApplicationController に実装済み
def authenticate_service!
  token = request.headers["Authorization"]&.delete_prefix("Bearer ")
  unless token == ENV.fetch("INTER_SERVICE_SECRET")
    render json: { error: "Unauthorized" }, status: :unauthorized
  end
end
```

認証失敗時は処理を中断し `401 Unauthorized` を返す（`return` は不要。`render` 後は後続の action が呼ばれない）。

### レスポンス形式

**成功レスポンス**

```json
// 単一リソース（create）
{ "notification": { "id": 1, "message": "...", ... } }

// コレクション（index）
{ "notifications": [ { "id": 1, ... }, ... ] }
```

**失敗レスポンス**

```json
// バリデーションエラー
{ "error": "エラーメッセージ" }

// 認証エラー
{ "error": "Unauthorized" }
```

### HTTP ステータスコード

| 操作 | 成功 | バリデーションエラー | 認証エラー |
|---|---|---|---|
| POST（create） | 201 Created | 422 Unprocessable Entity | 401 Unauthorized |
| GET（index） | 200 OK | — | 401 Unauthorized |

### コントローラの責務

コントローラは Service に委譲し、ロジックを直接書かない。

```ruby
# OK: Service に委譲
def create
  result = Notifications::CreateService.call(
    article_id: params[:article_id],
    message:    params[:message],
    user_id:    params[:user_id]
  )
  if result.success
    render json: { notification: result.value.as_json }, status: :created
  else
    render json: { error: result.error }, status: :unprocessable_entity
  end
end

# NG: コントローラに直接 ActiveRecord を書く
def create
  notification = Notification.create!(params.permit(...))
  render json: notification
end
```

### エンドポイント一覧

| メソッド | パス | 説明 |
|---|---|---|
| POST | `/api/v1/notifications` | 通知を作成する |
| GET | `/api/v1/notifications` | 未読通知一覧を返す（`user_id` パラメータ必須） |

### 既存実装

- コントローラ: `app/controllers/api/v1/notifications_controller.rb`
- 認証: `app/controllers/application_controller.rb`
