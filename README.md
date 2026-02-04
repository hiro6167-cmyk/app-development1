# PositiveVoice

ポジティブな声を集める投稿プラットフォーム

## 概要

PositiveVoiceは、中高生・大学生をターゲットにしたiOSアプリです。
ユーザーが「今日のいいこと」や「こうなって欲しい世の中」を投稿し、
似た考えを持つ人とつながることができます。

### 特徴

- **2種類の投稿** - 日常の良いことと、理想の世界像
- **AI自動分類** - 投稿を自動でカテゴリ分け
- **類似投稿表示** - 同じ想いを持つ人の投稿を発見
- **いいね機能なし** - 承認欲求を煽らない設計
- **モデレーション** - AIで不適切投稿を自動検出

## 技術スタック

### フロントエンド（iOS）
- Swift 5.x
- SwiftUI
- MVVM アーキテクチャ
- iOS 15.0+

### バックエンド（AWS）
- AWS Amplify
- Amazon Cognito（認証）
- Amazon DynamoDB（データベース）
- AWS Lambda（API）
- Amazon API Gateway
- Amazon S3（ストレージ）

### AI/機械学習
- Amazon Bedrock（Claude）- カテゴリ分類
- Amazon Comprehend - 感情分析、モデレーション

## プロジェクト構造

```
app-development1/
├── DESIGN.md                    # 設計ドキュメント
├── README.md                    # このファイル
│
├── docs/
│   └── WIREFRAMES.md           # UIワイヤーフレーム
│
├── PositiveVoice/              # iOSアプリ
│   ├── Package.swift
│   ├── amplifyconfiguration.json
│   ├── PositiveVoice.xcodeproj/
│   └── PositiveVoice/
│       ├── App/                # アプリエントリーポイント
│       ├── Models/             # データモデル
│       ├── ViewModels/         # ビューモデル
│       ├── Views/              # SwiftUI ビュー
│       ├── Services/           # AWS連携サービス
│       ├── Utils/              # ユーティリティ
│       └── Resources/          # アセット
│
├── backend/                    # AWSバックエンド
│   ├── template.yaml           # SAMテンプレート
│   ├── README.md
│   └── lambda/
│       ├── posts/              # 投稿API
│       └── ai/                 # AI API
│
└── scripts/
    └── setup.sh               # セットアップスクリプト
```

## セットアップ

### 前提条件

- macOS
- Xcode 15.0+
- AWS CLI v2
- AWS SAM CLI
- Apple Developer アカウント

### 1. リポジトリをクローン

```bash
git clone <repository-url>
cd app-development1
```

### 2. セットアップスクリプトを実行

```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### 3. Xcodeでプロジェクトを開く

```bash
open PositiveVoice/PositiveVoice.xcodeproj
```

### 4. AWS設定を更新

`PositiveVoice/amplifyconfiguration.json` を編集:

```json
{
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "CognitoUserPool": {
          "Default": {
            "PoolId": "YOUR_USER_POOL_ID",
            "AppClientId": "YOUR_APP_CLIENT_ID",
            "Region": "ap-northeast-1"
          }
        }
      }
    }
  }
}
```

### 5. バックエンドをデプロイ

```bash
cd backend
sam build
sam deploy --guided
```

## 開発

### iOSアプリのビルド

1. Xcodeでプロジェクトを開く
2. シミュレーターを選択
3. `Cmd + R` で実行

### バックエンドのローカルテスト

```bash
cd backend
sam local start-api
```

## API エンドポイント

| Method | Path | Description |
|--------|------|-------------|
| GET | /posts | 投稿一覧を取得 |
| POST | /posts | 新規投稿を作成 |
| GET | /posts/{id} | 投稿詳細を取得 |
| GET | /posts/{id}/similar | 類似投稿を取得 |
| GET | /posts/search | 投稿を検索 |
| POST | /ai/classify | AIでカテゴリ分類 |
| POST | /ai/moderate | 不適切コンテンツ検出 |

## ロードマップ

### Phase 1（MVP）
- [x] 基本的な投稿・閲覧機能
- [x] ユーザー認証（Apple/Google/Email）
- [x] AIカテゴリ自動分類
- [x] 類似投稿表示

### Phase 2
- [ ] 画像添付機能
- [ ] プッシュ通知
- [ ] ユーザー通報機能

### Phase 3
- [ ] 有料プラン（広告なし）
- [ ] 詳細な統計機能

### Phase 4
- [ ] Android版
- [ ] 企業向けデータ提供
