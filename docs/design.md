# design.md — 技術設計書

## 1. 技術スタック

| レイヤー | 選定技術 | 選定理由 |
|----------|----------|----------|
| 言語 | Swift 6.x | Apple公式、型安全性 |
| UI | SwiftUI | 宣言的UI、Apple推奨 |
| アーキテクチャ | MVVM | SwiftUIとの親和性、テスト容易性 |
| 非同期処理 | Swift Concurrency (async/await) | 構造化並行性 |
| データバインディング | @Observable | iOS 17+のリアクティブデータフロー |
| ローカルキャッシュ | UserDefaults + FileManager | シンプルなキャッシュ要件 |
| ネットワーク | URLSession + async/await | 標準ライブラリ、追加依存なし |
| バックエンド | AWS (Cognito, DynamoDB, Lambda, S3, API Gateway) | スケーラブル、無料枠あり |
| テスト | XCTest | 公式フレームワーク |
| 分析 | Firebase Analytics | 無料枠で十分 |

### 1.1 依存ライブラリ方針

- **最小限主義**: 標準ライブラリで実現できるものは外部ライブラリを使わない
- 現時点で外部ライブラリは不使用

---

## 2. アーキテクチャ設計

### 2.1 全体構成図

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │    View     │  │    View     │  │    View     │     │
│  │  (SwiftUI)  │  │  (SwiftUI)  │  │  (SwiftUI)  │     │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘     │
│         │                │                │             │
│  ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐     │
│  │  ViewModel  │  │  ViewModel  │  │  ViewModel  │     │
│  │ @Observable │  │ @Observable │  │ @Observable │     │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘     │
└─────────┼────────────────┼────────────────┼─────────────┘
          │                │                │
┌─────────▼────────────────▼────────────────▼─────────────┐
│                     Service Layer                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │ AuthService │  │ PostService │  │  AIService  │     │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘     │
└─────────┼────────────────┼────────────────┼─────────────┘
          │                │                │
┌─────────▼────────────────▼────────────────▼─────────────┐
│                     Network Layer                        │
│  ┌─────────────────────────────────────────────────┐   │
│  │              APIClient (URLSession)              │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────┐
│                   AWS Backend                            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │ Cognito  │ │ DynamoDB │ │  Lambda  │ │    S3    │  │
│  │  (認証)   │ │  (DB)    │ │  (API)   │ │ (画像)   │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 2.2 レイヤーの責務

| レイヤー | 責務 | 依存方向 |
|----------|------|----------|
| View | UI表示・ユーザー入力の受け取り | → ViewModel |
| ViewModel | 表示用データの変換・状態管理 | → Service |
| Service | ビジネスロジック・API呼び出し | → APIClient |
| APIClient | HTTP通信の抽象化 | → AWS |

### 2.3 状態管理方針

- 画面単位の状態: `@State` / `@Observable` ViewModel
- アプリ全体の状態: `AppState` を `@Environment` 経由で注入
- 永続化が必要な状態: UserDefaults / AWS DynamoDB
- 一時的な状態（ローディング等）: ViewModel内のenum

---

## 3. データモデル設計

### 3.1 主要エンティティ

```swift
// ユーザー
struct User: Identifiable, Codable {
    let id: String
    var nickname: String
    var avatarUrl: String?
    var bio: String?
    var postCount: Int
    var followerCount: Int
    var followingCount: Int
    let createdAt: Date
}

// 投稿
struct Post: Identifiable, Codable {
    let id: String
    let userId: String
    let type: PostType           // light | seed
    let content: String
    var imageUrls: [String]      // v2: 画像対応
    let category: PostCategory
    var commentCount: Int        // v2: コメント数
    var isBookmarked: Bool       // v2: ブックマーク
    let createdAt: Date

    // 関連データ（取得時に結合）
    var user: User?
}

enum PostType: String, Codable, CaseIterable {
    case light = "light"  // 今日あったいいこと
    case seed = "seed"    // 世界にこうなってほしい

    var displayName: String {
        switch self {
        case .light: return "今日あったいいこと"
        case .seed: return "世界にこうなってほしい"
        }
    }

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .seed: return "leaf.fill"
        }
    }
}

// コメント（v2）
struct Comment: Identifiable, Codable {
    let id: String
    let postId: String
    let userId: String
    let content: String
    let createdAt: Date

    var user: User?
}

// フォロー（v2）
struct Follow: Codable {
    let followerId: String
    let followeeId: String
    let createdAt: Date
}

// ブックマーク（v2）
struct Bookmark: Codable {
    let userId: String
    let postId: String
    let createdAt: Date
}

// カテゴリ
enum PostCategory: String, Codable, CaseIterable {
    case daily = "daily"           // 日常
    case work = "work"             // 仕事・勉強
    case relationship = "relationship"  // 人間関係
    case health = "health"         // 健康
    case hobby = "hobby"           // 趣味
    case food = "food"             // 食事
    case nature = "nature"         // 自然
    case gratitude = "gratitude"   // 感謝
    case achievement = "achievement" // 達成
    case other = "other"           // その他

    var displayName: String {
        switch self {
        case .daily: return "日常"
        case .work: return "仕事・勉強"
        case .relationship: return "人間関係"
        case .health: return "健康"
        case .hobby: return "趣味"
        case .food: return "食事"
        case .nature: return "自然"
        case .gratitude: return "感謝"
        case .achievement: return "達成"
        case .other: return "その他"
        }
    }

    var icon: String {
        switch self {
        case .daily: return "house.fill"
        case .work: return "briefcase.fill"
        case .relationship: return "person.2.fill"
        case .health: return "heart.fill"
        case .hobby: return "star.fill"
        case .food: return "fork.knife"
        case .nature: return "leaf.fill"
        case .gratitude: return "hands.clap.fill"
        case .achievement: return "trophy.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}
```

### 3.2 ER図

```
┌──────────────┐       ┌──────────────┐
│    Users     │       │    Posts     │
├──────────────┤       ├──────────────┤
│ id (PK)      │──┐    │ id (PK)      │
│ nickname     │  │    │ userId (FK)  │──┐
│ avatarUrl    │  │    │ type         │  │
│ bio          │  │    │ content      │  │
│ postCount    │  │    │ imageUrls[]  │  │
│ followerCount│  │    │ category     │  │
│ followingCnt │  └───▶│ commentCount │  │
│ createdAt    │       │ createdAt    │  │
└──────────────┘       └──────────────┘  │
       │                      │          │
       │                      ▼          │
       │               ┌──────────────┐  │
       │               │   Comments   │  │
       │               ├──────────────┤  │
       │               │ id (PK)      │  │
       │               │ postId (FK)  │──┘
       └──────────────▶│ userId (FK)  │
                       │ content      │
       ┌───────────────│ createdAt    │
       │               └──────────────┘
       │
       ▼
┌──────────────┐       ┌──────────────┐
│   Follows    │       │  Bookmarks   │
├──────────────┤       ├──────────────┤
│ followerId   │       │ userId (FK)  │
│ followeeId   │       │ postId (FK)  │
│ createdAt    │       │ createdAt    │
└──────────────┘       └──────────────┘
```

---

## 4. API設計

### 4.1 ベースURL
```
https://2qti95chy9.execute-api.ap-northeast-1.amazonaws.com/dev
```

### 4.2 エンドポイント一覧

| メソッド | パス | 説明 | 認証 |
|----------|------|------|------|
| **投稿** |
| GET | /posts | 投稿一覧取得 | 必要 |
| POST | /posts | 投稿作成 | 必要 |
| GET | /posts/{id} | 投稿詳細取得 | 必要 |
| DELETE | /posts/{id} | 投稿削除 | 必要 |
| GET | /posts/{id}/similar | 類似投稿取得 | 必要 |
| GET | /posts/search | 検索 | 必要 |
| GET | /posts/me | 自分の投稿 | 必要 |
| **コメント（v2）** |
| GET | /posts/{id}/comments | コメント一覧 | 必要 |
| POST | /posts/{id}/comments | コメント投稿 | 必要 |
| DELETE | /comments/{id} | コメント削除 | 必要 |
| **フォロー（v2）** |
| POST | /users/{id}/follow | フォロー | 必要 |
| DELETE | /users/{id}/follow | アンフォロー | 必要 |
| GET | /users/{id}/followers | フォロワー一覧 | 必要 |
| GET | /users/{id}/following | フォロー中一覧 | 必要 |
| **ブックマーク（v2）** |
| POST | /bookmarks/{postId} | ブックマーク追加 | 必要 |
| DELETE | /bookmarks/{postId} | ブックマーク削除 | 必要 |
| GET | /bookmarks | ブックマーク一覧 | 必要 |
| **メディア（v2）** |
| POST | /media/upload-url | S3署名付きURL取得 | 必要 |
| **AI** |
| POST | /ai/classify | カテゴリ分類 | 必要 |
| POST | /ai/moderate | 不適切コンテンツ検出 | 必要 |

### 4.3 エラーハンドリング

```swift
enum APIError: Error, LocalizedError {
    case networkUnavailable
    case unauthorized
    case forbidden
    case notFound
    case serverError(Int, String)
    case decodingFailed
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable: return "ネットワークに接続できません"
        case .unauthorized: return "ログインが必要です"
        case .forbidden: return "アクセス権限がありません"
        case .notFound: return "データが見つかりません"
        case .serverError(_, let msg): return msg
        case .decodingFailed: return "データの読み込みに失敗しました"
        case .unknown: return "予期しないエラーが発生しました"
        }
    }
}
```

---

## 5. 画面設計

### 5.1 画面一覧

| # | 画面名 | 説明 | ViewModel |
|---|--------|------|-----------|
| S1 | SplashView | 起動画面 | - |
| S2 | OnboardingView | 初回説明 | - |
| S3 | AuthView | ログイン/登録 | AuthViewModel |
| S4 | MainTabView | タブコンテナ | - |
| S5 | HomeView | タイムライン | HomeViewModel |
| S6 | CreatePostView | 投稿作成 | PostViewModel |
| S7 | PostDetailView | 投稿詳細 | PostViewModel |
| S8 | SearchView | 検索 | SearchViewModel |
| S9 | ProfileView | プロフィール | ProfileViewModel |
| S10 | UserProfileView | 他ユーザー（v2） | ProfileViewModel |
| S11 | SettingsView | 設定 | SettingsViewModel |
| S12 | CommentsView | コメント一覧（v2） | CommentsViewModel |
| S13 | BookmarksView | ブックマーク（v2） | BookmarksViewModel |
| S14 | FollowListView | フォロー一覧（v2） | FollowViewModel |

### 5.2 ナビゲーション構造

```
TabView
├── Tab1 (ホーム): NavigationStack
│   ├── HomeView
│   │   ├── PostDetailView ← push
│   │   │   ├── CommentsView ← push
│   │   │   └── UserProfileView ← push
│   │   └── CreatePostView ← sheet
│   └── UserProfileView ← push
├── Tab2 (検索): NavigationStack
│   ├── SearchView
│   │   └── PostDetailView ← push
├── Tab3 (プロフィール): NavigationStack
│   ├── ProfileView
│   │   ├── BookmarksView ← push
│   │   ├── FollowListView ← push
│   │   └── SettingsView ← push
```

### 5.3 カラーパレット（v2更新）

```swift
enum AppColors {
    // メインカラー（温かいオレンジ系）
    static let primary = Color(hex: "FF8C42")      // 温かいオレンジ
    static let secondary = Color(hex: "FFD166")    // 明るいイエロー
    static let accent = Color(hex: "F4845F")       // コーラル

    // 背景
    static let background = Color(hex: "FFF8F0")   // クリーム
    static let surface = Color.white

    // テキスト
    static let textPrimary = Color(hex: "5D4037")  // ブラウン
    static let textSecondary = Color(hex: "8D6E63") // ライトブラウン

    // 状態
    static let success = Color(hex: "7CB342")      // ライトグリーン
    static let error = Color(hex: "E57373")        // ソフトレッド

    // グラデーション
    static let warmGradient = LinearGradient(
        colors: [Color(hex: "FF8C42"), Color(hex: "FFD166")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // ダークモード用
    static let darkBackground = Color(hex: "1A1A1A")
    static let darkSurface = Color(hex: "2D2D2D")
    static let darkPrimary = Color(hex: "FFB266")
}
```

---

## 6. ディレクトリ構成

```
PositiveVoice/
├── PositiveVoice/
│   ├── App/
│   │   ├── PositiveVoiceApp.swift
│   │   ├── ContentView.swift
│   │   └── AppState.swift
│   ├── Models/
│   │   ├── User.swift
│   │   ├── Post.swift
│   │   ├── Comment.swift
│   │   ├── PostCategory.swift
│   │   └── Follow.swift
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift
│   │   ├── HomeViewModel.swift
│   │   ├── PostViewModel.swift
│   │   ├── SearchViewModel.swift
│   │   ├── ProfileViewModel.swift
│   │   ├── CommentsViewModel.swift
│   │   └── SettingsViewModel.swift
│   ├── Views/
│   │   ├── Splash/
│   │   ├── Onboarding/
│   │   ├── Auth/
│   │   ├── Home/
│   │   ├── Post/
│   │   ├── Search/
│   │   ├── Profile/
│   │   ├── Settings/
│   │   └── Components/
│   ├── Services/
│   │   ├── APIClient.swift
│   │   ├── AuthService.swift
│   │   ├── PostService.swift
│   │   ├── CommentService.swift
│   │   ├── FollowService.swift
│   │   ├── BookmarkService.swift
│   │   └── AIService.swift
│   ├── Utils/
│   │   ├── Constants.swift
│   │   ├── Extensions/
│   │   └── Helpers/
│   └── Resources/
│       ├── Assets.xcassets
│       └── Info.plist
├── PositiveVoiceTests/
└── docs/
    ├── product.md
    ├── design.md
    ├── tasks.md
    └── constitution.md
```

---

## 7. セキュリティ設計

| 対策項目 | 実装方針 |
|----------|----------|
| 認証 | AWS Cognito（メール/パスワード） |
| トークン管理 | Keychain保存、自動リフレッシュ |
| API通信 | HTTPS必須 |
| 画像アップロード | S3署名付きURL（有効期限15分） |
| 入力バリデーション | クライアント + サーバーサイド両方 |
| 不適切コンテンツ | AI自動検出 + 報告機能 |

---

## 8. アクセシビリティ設計

| 項目 | 対応方針 |
|------|----------|
| VoiceOver | 全要素に `.accessibilityLabel()` |
| Dynamic Type | セマンティックフォント使用 |
| ダークモード | 完全対応（v2） |
| コントラスト | WCAG AA基準（4.5:1以上） |
| タップターゲット | 最小44pt × 44pt |
