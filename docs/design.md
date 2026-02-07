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
        case .seed: return "sparkles"  // leaf.fillは緑を想起させるため禁止
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
        case .nature: return "cloud.sun.fill"  // leaf.fillは緑を想起させるため禁止
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

### 4.3 ページネーション・ソート・フィルタ仕様

#### 一覧取得API共通仕様

**リクエストパラメータ:**
| パラメータ | 型 | 必須 | デフォルト | 説明 |
|-----------|------|------|-----------|------|
| limit | Int | No | 20 | 取得件数（最大50） |
| cursor | String | No | null | ページングカーソル（DynamoDB LastEvaluatedKey） |
| sort | String | No | "newest" | ソート順（newest / recommended） |

**GET /posts 追加パラメータ:**
| パラメータ | 型 | 必須 | 説明 |
|-----------|------|------|------|
| type | String | No | "light" or "seed"（指定なしで両方） |
| category | String | No | カテゴリフィルタ |

**GET /posts/search 追加パラメータ:**
| パラメータ | 型 | 必須 | 説明 |
|-----------|------|------|------|
| q | String | Yes | 検索キーワード |
| type | String | No | 投稿タイプフィルタ |
| category | String | No | カテゴリフィルタ |

**レスポンス形式（一覧系共通）:**
```json
{
  "items": [...],
  "nextCursor": "eyJpZCI6Inh4eCIsImNyZWF0ZWRBdCI6Ii4uLiJ9",
  "hasMore": true
}
```

#### カーソル型・エンコード規約

**サーバー側（Lambda）:**
- DynamoDBの `LastEvaluatedKey` をBase64エンコードして返却
- 内部構造: `{"id": "xxx", "createdAt": "2025-02-07T10:00:00Z"}` → Base64
- クライアントは内部構造を解釈しない（透過扱い）

**クライアント側:**
```swift
// カーソルは不透明な文字列として扱う（デコード禁止）
struct PaginatedResponse<T: Decodable>: Decodable {
    let items: [T]
    let nextCursor: String?  // サーバーから受け取ったままの文字列
    let hasMore: Bool
}

// リクエスト時もそのまま送信
func fetchPosts(cursor: String? = nil) async throws -> PaginatedResponse<Post> {
    var params: [String: String] = ["limit": "20"]
    if let cursor = cursor {
        params["cursor"] = cursor  // エンコードせずそのまま
    }
    return try await apiClient.get("/posts", params: params)
}

// ViewModel での保持
@Observable
class HomeViewModel {
    private(set) var posts: [Post] = []
    private var nextCursor: String?  // 型は String?（透過）
    private(set) var hasMore: Bool = true

    func loadMore() async {
        guard hasMore, nextCursor != nil else { return }
        let response = try await postService.fetchPosts(cursor: nextCursor)
        posts.append(contentsOf: response.items)
        nextCursor = response.nextCursor
        hasMore = response.hasMore
    }
}
```

**禁止事項:**
- クライアントでcursorをBase64デコードしない
- cursorの内容に依存したロジックを書かない
- cursorを永続化しない（セッション中のメモリ保持のみ）

### 4.4 エラーレスポンス標準仕様

**サーバーエラーレスポンス形式:**
```json
{
  "message": "エラーメッセージ（ユーザー表示用）",
  "code": "ERROR_CODE",
  "details": {}  // オプション：デバッグ情報
}
```

**エラーコード一覧:**
| HTTPステータス | code | 説明 |
|---------------|------|------|
| 400 | INVALID_REQUEST | リクエスト不正 |
| 401 | TOKEN_EXPIRED | Cognitoトークン期限切れ |
| 401 | UNAUTHORIZED | 認証なし |
| 403 | FORBIDDEN | 権限なし（他人の投稿削除等） |
| 404 | NOT_FOUND | リソースが存在しない |
| 409 | ALREADY_EXISTS | 重複（既にフォロー中等） |
| 422 | VALIDATION_ERROR | バリデーションエラー |
| 429 | RATE_LIMITED | レート制限超過 |
| 500 | INTERNAL_ERROR | サーバー内部エラー |

**APIClient変換ルール:**
```swift
func mapError(statusCode: Int, body: ErrorResponse?) -> APIError {
    switch statusCode {
    case 401 where body?.code == "TOKEN_EXPIRED":
        return .tokenExpired  // → refresh試行
    case 401:
        return .unauthorized  // → ログイン画面へ
    case 403:
        return .forbidden
    case 404:
        return .notFound
    case 400, 422:
        return .validationError(body?.message ?? "入力内容を確認してください")
    case 429:
        return .rateLimited
    case 500...:
        return .serverError(statusCode, body?.message ?? "サーバーエラー")
    default:
        return .unknown
    }
}
```

### 4.5 エラーハンドリング（クライアント）

```swift
enum APIError: Error, LocalizedError {
    case networkUnavailable
    case tokenExpired          // → 自動refresh試行
    case unauthorized          // → ログイン画面へ
    case forbidden
    case notFound
    case validationError(String)
    case rateLimited
    case serverError(Int, String)
    case decodingFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .networkUnavailable: return "ネットワークに接続できません"
        case .tokenExpired: return "セッションが切れました"
        case .unauthorized: return "ログインが必要です"
        case .forbidden: return "アクセス権限がありません"
        case .notFound: return "データが見つかりません"
        case .validationError(let msg): return msg
        case .rateLimited: return "しばらく待ってから再試行してください"
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

**重要**: 緑系の色は一切使用禁止。全色はConstants.swiftに集約、ドキュメントは参考情報。

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

    // 状態（緑禁止：オレンジ系で統一）
    static let success = Color(hex: "FFB347")      // オレンジ系（緑は使用禁止）
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
    static let darkSuccess = Color(hex: "FFCC80")  // ダーク用オレンジ系
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
| 認証 | AWS Cognito（User Pool + SRP認証フロー） |
| トークン管理 | Keychain保存、自動リフレッシュ（下記詳細） |
| API通信 | HTTPS必須 |
| 画像アップロード | S3署名付きURL（有効期限15分）（下記詳細） |
| 入力バリデーション | クライアント + サーバーサイド両方 |
| 不適切コンテンツ | AI自動検出 + 報告機能 |

### 7.1 Cognito トークン管理詳細

**トークン種別と用途:**
| トークン | 保存先 | 用途 | 有効期限 |
|---------|--------|------|---------|
| ID Token | Keychain | API認証ヘッダー | 1時間 |
| Access Token | メモリのみ | Cognito API操作 | 1時間 |
| Refresh Token | Keychain | トークン更新 | 30日 |

**トークン更新フロー:**
```
1. APIリクエスト送信
2. 401 (TOKEN_EXPIRED) 受信
3. AuthService.refreshToken() 呼び出し
   - 排他制御: 同時多発リクエストは単一フライトに集約
   - Refresh Token → Cognito → 新ID Token取得
4. 成功時: Keychain更新 → 元リクエストをリトライ（冪等なGETのみ）
5. 失敗時: ログイン画面へ遷移
```

**単一フライト実装パターン（actor方式）:**
```swift
actor TokenRefresher {
    private var refreshTask: Task<String, Error>?

    func refreshIfNeeded() async throws -> String {
        // 既に進行中のリフレッシュがあれば、それを待つ
        if let existingTask = refreshTask {
            return try await existingTask.value
        }

        // 新規リフレッシュタスクを作成
        let task = Task<String, Error> {
            defer { refreshTask = nil }

            guard let refreshToken = KeychainHelper.get(.refreshToken) else {
                throw AuthError.noRefreshToken
            }

            let newTokens = try await CognitoClient.refresh(refreshToken)
            KeychainHelper.set(.idToken, newTokens.idToken)
            return newTokens.idToken
        }

        refreshTask = task
        return try await task.value
    }
}

// 使用例（APIClient内）
private let tokenRefresher = TokenRefresher()

func request<T>(_ endpoint: Endpoint) async throws -> T {
    do {
        return try await performRequest(endpoint)
    } catch APIError.tokenExpired {
        let newToken = try await tokenRefresher.refreshIfNeeded()
        return try await performRequest(endpoint, token: newToken)
    }
}
```

**選定理由:**
- actor: Swift Concurrency標準、データ競合を言語レベルで防止
- Task共有: 同時多発リクエストが1つのリフレッシュを共有
- AsyncLock不採用: 外部ライブラリ依存を避ける

**サインアウト時の処理:**
- Keychain: ID Token, Refresh Token 削除
- メモリ: Access Token, ユーザー情報 クリア
- ローカルキャッシュ: 全削除
- Cognito: globalSignOut 呼び出し（他デバイスも無効化）

### 7.2 画像アップロード詳細

**Info.plist 必須キー:**
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>投稿に画像を添付するために写真へのアクセスが必要です</string>
```

**アップロードフロー:**
```
1. PhotosPicker で画像選択（最大4枚）
2. 前処理:
   - HEIC → JPEG変換
   - 長辺1080pxにリサイズ
   - EXIF（位置情報含む）完全削除
   - 圧縮率0.8でJPEGエンコード
3. POST /media/upload-url で署名付きURL取得
4. 並列アップロード（最大2並列）
5. 失敗時: 3回までリトライ
6. 全リトライ失敗: 該当画像スキップ、ユーザーに通知
7. 成功した画像URLを投稿データに含めて送信
```

**制限:**
- 1枚あたり最大5MB（リサイズ後）
- 対応形式: JPEG, PNG, HEIC（サーバー保存はJPEG統一）
- 署名付きURLの有効期限: 15分

#### EXIF除去の実装方針

**方針:** CGImageDestination でメタデータなしのJPEGを新規作成（既存画像のメタデータを「削除」するのではなく、「含めずに新規作成」する）

```swift
import ImageIO
import UniformTypeIdentifiers

enum ImageProcessor {
    /// 画像をEXIFなしJPEGに変換（リサイズ含む）
    static func processForUpload(_ data: Data, maxSize: CGFloat = 1080) throws -> Data {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ImageError.invalidData
        }

        // リサイズ
        let resizedImage = resize(cgImage, maxSize: maxSize)

        // EXIF除去してJPEGエンコード（メタデータを一切含めない）
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw ImageError.encodingFailed
        }

        // kCGImageDestinationLossyCompressionQuality のみ指定
        // メタデータ系のキーを一切渡さない = EXIFなし
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.8
        ]

        CGImageDestinationAddImage(destination, resizedImage, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw ImageError.encodingFailed
        }

        return mutableData as Data
    }

    private static func resize(_ image: CGImage, maxSize: CGFloat) -> CGImage {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let maxDimension = max(width, height)

        guard maxDimension > maxSize else { return image }

        let scale = maxSize / maxDimension
        let newWidth = Int(width * scale)
        let newHeight = Int(height * scale)

        let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

        return context.makeImage()!
    }
}
```

**検証方法:**
```swift
// 開発時のみ: 出力にEXIFが含まれていないことを確認
#if DEBUG
func verifyNoExif(_ data: Data) -> Bool {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
          let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
        return true
    }
    // GPS, EXIF, TIFFが含まれていないことを確認
    let sensitiveKeys = [kCGImagePropertyGPSDictionary, kCGImagePropertyExifDictionary]
    return sensitiveKeys.allSatisfy { properties[$0 as String] == nil }
}
#endif
```

**禁止事項:**
- CGImageSourceCopyProperties で取得したメタデータを部分削除する方式（漏れのリスク）
- UIImageのJPEGRepresentationを直接使う（EXIFが残る可能性）

---

## 8. ローカルキャッシュ設計

### 8.1 ブックマークキャッシュ整合方針

**前提:** サーバーが正（Single Source of Truth）

**キャッシュ構造:**
```swift
// UserDefaults キー
enum CacheKeys {
    static let bookmarkedPostIds = "bookmarked_post_ids"  // Set<String>
    static let bookmarksSyncedAt = "bookmarks_synced_at"  // Date
}
```

**同期フロー:**

```
┌─────────────────────────────────────────────────────────────────┐
│                      アプリ起動時                                 │
├─────────────────────────────────────────────────────────────────┤
│ 1. ローカルキャッシュでUI即時表示（UX優先）                        │
│ 2. バックグラウンドでサーバー同期                                 │
│ 3. 差分があればローカル更新 → UI反映                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                   ブックマーク追加/削除時                          │
├─────────────────────────────────────────────────────────────────┤
│ 1. ローカルキャッシュを楽観的更新（即時UI反映）                     │
│ 2. サーバーAPIを呼び出し                                          │
│ 3. 成功: 完了                                                    │
│ 4. 失敗: ローカルをロールバック + エラー表示                       │
└─────────────────────────────────────────────────────────────────┘
```

**実装:**
```swift
@Observable
class BookmarkService {
    private(set) var bookmarkedPostIds: Set<String> = []
    private var pendingOperations: [String: BookmarkOperation] = [:]

    enum BookmarkOperation { case add, remove }

    init() {
        // 起動時: ローカルキャッシュ読み込み
        loadFromCache()
    }

    func syncWithServer() async {
        do {
            let serverBookmarks = try await apiClient.get("/bookmarks")
            let serverIds = Set(serverBookmarks.map { $0.postId })

            // サーバーが正
            bookmarkedPostIds = serverIds
            saveToCache()
        } catch {
            // 同期失敗時はローカルのまま継続（次回起動時に再試行）
            Logger.warning("Bookmark sync failed: \(error)")
        }
    }

    func toggle(_ postId: String) async throws {
        let isCurrentlyBookmarked = bookmarkedPostIds.contains(postId)

        // 楽観的更新
        if isCurrentlyBookmarked {
            bookmarkedPostIds.remove(postId)
        } else {
            bookmarkedPostIds.insert(postId)
        }
        saveToCache()

        do {
            if isCurrentlyBookmarked {
                try await apiClient.delete("/bookmarks/\(postId)")
            } else {
                try await apiClient.post("/bookmarks/\(postId)")
            }
        } catch {
            // ロールバック
            if isCurrentlyBookmarked {
                bookmarkedPostIds.insert(postId)
            } else {
                bookmarkedPostIds.remove(postId)
            }
            saveToCache()
            throw error
        }
    }

    private func loadFromCache() {
        if let ids = UserDefaults.standard.array(forKey: CacheKeys.bookmarkedPostIds) as? [String] {
            bookmarkedPostIds = Set(ids)
        }
    }

    private func saveToCache() {
        UserDefaults.standard.set(Array(bookmarkedPostIds), forKey: CacheKeys.bookmarkedPostIds)
    }
}
```

**エッジケース対応:**
| ケース | 対応 |
|--------|------|
| オフラインでブックマーク | 楽観的更新のみ、次回オンライン時に同期 |
| 同期中に操作 | 操作を優先、同期結果はマージ |
| サーバーで削除済み投稿 | 同期時にローカルから除外 |
| ログアウト | ローカルキャッシュ全削除 |

---

## 9. アクセシビリティ設計

| 項目 | 対応方針 |
|------|----------|
| VoiceOver | 全要素に `.accessibilityLabel()` |
| Dynamic Type | セマンティックフォント使用 |
| ダークモード | 完全対応（v2） |
| コントラスト | WCAG AA基準（4.5:1以上） |
| タップターゲット | 最小44pt × 44pt |

---

## 10. Firebase Analytics 設計

### 10.1 プライバシーポリシーとの整合

プライバシーポリシー記載の「利用データ」に対応するイベントを定義。
**収集するデータは匿名化され、個人を特定する情報は含まない。**

### 10.2 イベント一覧

| イベント名 | 説明 | パラメータ | プライバシーポリシー対応 |
|-----------|------|-----------|------------------------|
| **画面表示** |
| `screen_view` | 画面表示 | `screen_name`, `screen_class` | 閲覧履歴 |
| **認証** |
| `sign_up` | 新規登録完了 | `method: "email"` | - |
| `login` | ログイン成功 | `method: "email"` | - |
| `logout` | ログアウト | - | - |
| **投稿** |
| `post_create` | 投稿作成 | `post_type`, `category`, `has_image` | 利用状況 |
| `post_view` | 投稿詳細表示 | `post_id`, `post_type` | 閲覧履歴 |
| `post_delete` | 投稿削除 | `post_id` | - |
| **エンゲージメント** |
| `bookmark_add` | ブックマーク追加 | `post_id` | 利用状況 |
| `bookmark_remove` | ブックマーク削除 | `post_id` | - |
| `comment_create` | コメント投稿 | `post_id` | 利用状況 |
| `share` | シェア | `post_id`, `method` | 利用状況 |
| **ソーシャル** |
| `follow` | フォロー | `target_user_id` | 利用状況 |
| `unfollow` | アンフォロー | `target_user_id` | - |
| **検索** |
| `search` | 検索実行 | `search_term`, `result_count` | 利用状況 |
| `category_filter` | カテゴリフィルタ | `category` | 利用状況 |
| **エラー** |
| `error` | エラー発生 | `error_code`, `screen_name` | - |

### 10.3 実装ガイドライン

```swift
import FirebaseAnalytics

enum AnalyticsEvent {
    case postCreate(type: PostType, category: PostCategory, hasImage: Bool)
    case postView(postId: String, type: PostType)
    case bookmarkAdd(postId: String)
    case search(term: String, resultCount: Int)
    // ... その他

    var name: String {
        switch self {
        case .postCreate: return "post_create"
        case .postView: return "post_view"
        case .bookmarkAdd: return "bookmark_add"
        case .search: return "search"
        }
    }

    var parameters: [String: Any] {
        switch self {
        case .postCreate(let type, let category, let hasImage):
            return [
                "post_type": type.rawValue,
                "category": category.rawValue,
                "has_image": hasImage
            ]
        case .postView(let postId, let type):
            return [
                "post_id": postId,
                "post_type": type.rawValue
            ]
        case .bookmarkAdd(let postId):
            return ["post_id": postId]
        case .search(let term, let resultCount):
            return [
                "search_term": term,
                "result_count": resultCount
            ]
        }
    }

    func log() {
        Analytics.logEvent(name, parameters: parameters)
    }
}

// 使用例
AnalyticsEvent.postCreate(type: .light, category: .daily, hasImage: true).log()
```

### 10.4 収集しないデータ（明示的除外）

| データ | 理由 |
|--------|------|
| 投稿本文 | プライバシー保護 |
| ユーザー名・メールアドレス | 個人特定情報 |
| 位置情報 | 未使用機能 |
| 端末識別子（IDFA） | ATT未対応のため |

### 10.5 App Store プライバシーラベル対応

| データ種類 | 収集する | 用途 | ユーザーにリンク |
|-----------|---------|------|----------------|
| 識別子 | No | - | - |
| 使用状況データ | Yes | アプリ機能・分析 | No（匿名） |
| 診断 | Yes | クラッシュデータ | No |
