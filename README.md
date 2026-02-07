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
- **画像添付** - 投稿に画像を追加（最大4枚）
- **コメント・ブックマーク** - 投稿へのエンゲージメント
- **フォロー機能** - ユーザー同士のつながり
- **ダークモード** - システム連動/手動切り替え対応

### デザインテーマ

温かみのあるオレンジ系カラーパレットを採用。ポジティブで明るい印象を演出します。

| 色 | 用途 | カラーコード |
|----|------|-------------|
| Primary | メインカラー | #FF8C42 |
| Secondary | アクセント | #FFD166 |
| Accent | 強調 | #F4845F |
| Background | 背景 | #FFF8F0 |

## 技術スタック

### フロントエンド（iOS）
- Swift 6.x
- SwiftUI
- MVVM アーキテクチャ
- iOS 17.0+
- Observation framework (@Observable)

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
├── CLAUDE.md                    # プロジェクトルール
├── README.md                    # このファイル
│
├── docs/
│   ├── WIREFRAMES.md           # UIワイヤーフレーム
│   └── feature-update-v2.md    # v2.0設計書
│
├── PositiveVoice/              # iOSアプリ
│   ├── PositiveVoice.xcodeproj/
│   └── PositiveVoice/
│       ├── App/                # アプリエントリーポイント
│       │   ├── AppState.swift
│       │   └── ContentView.swift
│       ├── Models/             # データモデル
│       │   ├── Post.swift
│       │   ├── User.swift
│       │   ├── Comment.swift
│       │   ├── Follow.swift
│       │   ├── Bookmark.swift
│       │   └── PostCategory.swift
│       ├── ViewModels/         # ビューモデル
│       │   ├── AuthViewModel.swift
│       │   ├── HomeViewModel.swift
│       │   ├── ProfileViewModel.swift
│       │   └── CommentsViewModel.swift
│       ├── Views/              # SwiftUI ビュー
│       │   ├── Home/
│       │   ├── Post/
│       │   ├── Profile/
│       │   ├── Settings/
│       │   └── Splash/
│       ├── Services/           # AWS連携サービス
│       │   ├── BookmarkService.swift
│       │   ├── CommentService.swift
│       │   ├── FollowService.swift
│       │   └── ImageService.swift
│       ├── Utils/              # ユーティリティ
│       │   ├── Constants.swift
│       │   └── Animations.swift
│       └── Resources/          # アセット
│
├── backend/                    # AWSバックエンド
│   ├── template.yaml           # SAMテンプレート
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
- Xcode 16.0+
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

### 投稿
| Method | Path | Description |
|--------|------|-------------|
| GET | /posts | 投稿一覧を取得 |
| POST | /posts | 新規投稿を作成 |
| GET | /posts/{id} | 投稿詳細を取得 |
| GET | /posts/{id}/similar | 類似投稿を取得 |
| GET | /posts/search | 投稿を検索 |

### コメント
| Method | Path | Description |
|--------|------|-------------|
| GET | /posts/{id}/comments | コメント一覧を取得 |
| POST | /posts/{id}/comments | コメントを追加 |
| DELETE | /comments/{id} | コメントを削除 |

### ブックマーク
| Method | Path | Description |
|--------|------|-------------|
| GET | /bookmarks | ブックマーク一覧を取得 |
| POST | /posts/{id}/bookmark | ブックマークを追加 |
| DELETE | /posts/{id}/bookmark | ブックマークを削除 |

### フォロー
| Method | Path | Description |
|--------|------|-------------|
| GET | /users/{id}/followers | フォロワー一覧 |
| GET | /users/{id}/following | フォロー中一覧 |
| POST | /users/{id}/follow | フォローする |
| DELETE | /users/{id}/follow | フォロー解除 |

### AI
| Method | Path | Description |
|--------|------|-------------|
| POST | /ai/classify | AIでカテゴリ分類 |
| POST | /ai/moderate | 不適切コンテンツ検出 |

## ロードマップ

### Phase 1（MVP）✅
- [x] 基本的な投稿・閲覧機能
- [x] ユーザー認証（Email/Password）
- [x] AIカテゴリ自動分類
- [x] 類似投稿表示

### Phase 2（v2.0）✅
- [x] ブランディング刷新（オレンジテーマ）
- [x] 画像添付機能（最大4枚、EXIF削除）
- [x] コメント機能
- [x] ブックマーク機能（楽観的更新）

### Phase 3（v2.0）✅
- [x] フォロー/フォロワー機能
- [x] 他ユーザープロフィール画面
- [x] プロフィール画面の投稿/ブックマークタブ

### Phase 4（v2.0）✅
- [x] ダークモード対応（システム連動/手動）
- [x] UIアニメーション強化
- [x] スプラッシュ画面刷新

### 今後の予定
- [ ] プッシュ通知
- [ ] ユーザー通報機能
- [ ] 有料プラン（広告なし）
- [ ] Android版
