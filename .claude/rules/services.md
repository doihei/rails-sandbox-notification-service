## Service Object の規約

### 基本方針

- `ApplicationService` は使わず、各サービスクラスが `self.call` クラスメソッドを持つ。
- 戻り値は `Data.define` で定義した Result 型を返す。
- ネームスペースはリソース名の複数形モジュールに統一する（例: `Notifications::CreateService`）。
- ファイル配置: `app/services/<namespace>/<action>_service.rb`

### Result 型

```ruby
Result = Data.define(:success, :value, :error)

# 成功
Result.new(success: true, value: notification, error: nil)

# 失敗
Result.new(success: false, value: nil, error: "エラーメッセージ")
```

呼び出し側は `result.success` で成否を判定する。

```ruby
result = Notifications::CreateService.call(...)
if result.success
  render json: { notification: result.value.as_json }, status: :created
else
  render json: { error: result.error }, status: :unprocessable_entity
end
```

### 実装パターン

```ruby
module Notifications
  class CreateService
    Result = Data.define(:success, :value, :error)

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(article_id:, message:, user_id:)
      @article_id = article_id
      @message    = message
      @user_id    = user_id
    end

    def call
      record = Notification.new(
        article_id: @article_id,
        message:    @message,
        user_id:    @user_id
      )

      if record.save
        Result.new(success: true, value: record, error: nil)
      else
        Result.new(success: false, value: nil, error: record.errors.full_messages.first)
      end
    end
  end
end
```

### 既存実装

参考実装: `app/services/notifications/create_service.rb`

### 注意

- `self.call` の引数と `initialize` の引数は必ず一致させる（typo に注意）。
- バリデーションエラーは `record.errors.full_messages.first` で文字列として取り出す。
- サービスにビジネスロジックを集約し、コントローラには書かない。
