## Docker 構成

### サービス構成

| サービス | コンテナ名 | 役割 | ホストポート |
|---|---|---|---|
| Rails API | `notification-api` | API サーバー（Rails 8.1） | 3001 |
| PostgreSQL | `notification-db` | データベース（PostgreSQL 16） | 5433 |

DB のホストポートを 5433 にしているのは、rails-sandbox-backend の 5432 と衝突しないためのオフセット。

### 起動・操作コマンド

```bash
# 起動
docker compose up -d

# 停止
docker compose down

# ログ確認
docker compose logs -f notification-api

# Rails コマンド実行（必ずこの形式で）
docker compose exec notification-api bin/rails db:migrate
docker compose exec notification-api bin/rails console
docker compose exec notification-api bundle exec rspec
```

### 環境変数

環境変数は `.env` で管理する（`.env.example` をコピーして作成）。
`docker-compose.yml` の `env_file: .env` 経由で両サービスに渡される。

| 変数名 | 用途 |
|---|---|
| `POSTGRES_USER` | PostgreSQL ユーザー名 |
| `POSTGRES_PASSWORD` | PostgreSQL パスワード |
| `POSTGRES_DB` | PostgreSQL データベース名（development） |
| `DATABASE_URL` | Rails の DB 接続 URL |
| `INTER_SERVICE_SECRET` | サービス間認証トークン（backend 側と同じ値を設定） |

`RAILS_ENV` は `docker-compose.yml` の `environment:` セクションで `development` を明示している。

### Dockerfile.dev と dev-entrypoint

`docker/Dockerfile.dev` は開発専用イメージ。WORKDIR は `/app`。

`docker/dev-entrypoint` が起動時に以下を自動実行する:
1. `bundle install`（Gemfile.lock に変化があれば自動更新）
2. `bin/rails db:prepare`（DB 未作成なら作成、マイグレーション未適用なら適用）
3. `tmp/pids/server.pid` の削除（前回の異常終了残骸を除去）

### よくあるトラブル

**DB 環境ミスマッチ（ActiveRecord::EnvironmentMismatchError）**

テスト実行時に development 環境で作成された DB を test が参照できないエラー。

```bash
docker compose exec notification-api bin/rails db:environment:set RAILS_ENV=test
```

**bundle_cache ボリュームのキャッシュ問題**

Gem の依存関係がおかしくなった場合はボリュームごと削除して再構築する。

```bash
docker compose down -v
docker compose up -d
```
