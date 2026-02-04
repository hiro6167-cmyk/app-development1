# PositiveVoice Backend

AWS SAMを使用したサーバーレスバックエンド

## アーキテクチャ

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   iOS App   │────▶│ API Gateway │────▶│   Lambda    │
└─────────────┘     └─────────────┘     └─────────────┘
                           │                   │
                           ▼                   ▼
                    ┌─────────────┐     ┌─────────────┐
                    │   Cognito   │     │  DynamoDB   │
                    └─────────────┘     └─────────────┘
                                              │
                                              ▼
                                       ┌─────────────┐
                                       │   Bedrock   │
                                       │ Comprehend  │
                                       └─────────────┘
```

## 前提条件

- AWS CLI v2
- AWS SAM CLI
- Python 3.11

## デプロイ

### 1. 初回デプロイ

```bash
# ビルド
sam build

# デプロイ（対話形式）
sam deploy --guided
```

### 2. 以降のデプロイ

```bash
sam build && sam deploy
```

## API エンドポイント

### Posts API

| Method | Path | Description |
|--------|------|-------------|
| GET | /posts | 投稿一覧を取得 |
| POST | /posts | 新規投稿を作成 |
| GET | /posts/{id} | 投稿詳細を取得 |
| DELETE | /posts/{id} | 投稿を削除 |
| GET | /posts/{id}/similar | 類似投稿を取得 |
| GET | /posts/search | 投稿を検索 |
| GET | /posts/me | 自分の投稿を取得 |

### AI API

| Method | Path | Description |
|--------|------|-------------|
| POST | /ai/classify | 投稿をカテゴリに分類 |
| POST | /ai/moderate | 不適切コンテンツを検出 |
| POST | /ai/embedding | 埋め込みベクトルを生成 |
| POST | /ai/sentiment | 感情分析 |

## 環境変数

Lambda関数で使用する環境変数:

- `POSTS_TABLE`: 投稿テーブル名
- `USERS_TABLE`: ユーザーテーブル名

## ローカルテスト

```bash
# ローカルAPI起動
sam local start-api

# 特定の関数をテスト
sam local invoke PostsFunction --event events/get-posts.json
```

## 本番環境へのデプロイ

```bash
sam deploy --parameter-overrides Environment=prod
```
