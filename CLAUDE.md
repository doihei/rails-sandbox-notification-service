# rails-sandbox-notification-service

Rails 8.1 API-only + PostgreSQL の通知マイクロサービス。
backend から `POST /api/v1/notifications` で受け取り、通知レコードを保存・配信する。

## 開発環境の絶対原則

- **ローカルの Ruby / PostgreSQL は使わない。docker-compose で全て動かす。**
- Rails コマンドは必ず `docker compose exec notification-api bin/rails <コマンド>` 経由で実行する。

## コンテキストの参照先

- Docker 構成・環境変数 → `.claude/rules/docker.md`
- テスト実行規約 → `.claude/rules/testing.md`
- Service Object の実装規約 → `.claude/rules/services.md`
- REST API・認証の実装規約 → `.claude/rules/api.md`
- 人間向けセットアップガイド → `README.md`
