# CLAUDE.md — PositiveVoice プロジェクトルール

## 🔴 絶対ルール（MUST）

### ファイル操作の禁止事項
- **絶対に .pbxproj ファイルを直接編集しない**。ファイル作成後、Xcodeへの追加は人間が手動で行う
- **絶対に既存コードを全面書き換えしない**。変更は最小限の差分で行う
- **絶対にマジックナンバー・ハードコードされた文字列を使わない**。Constants.swift に定義する

### コーディング規約
- 言語: Swift 6.x（最新安定版）
- UI: SwiftUI（UIKitは明示的な理由がある場合のみ）
- アーキテクチャ: MVVM（View → ViewModel → Service/Repository）
- any型・force unwrap(!)の使用禁止。guard let / if let を使う
- 関数は50行以内。1関数1責務
- 命名規則: Apple Swift API Design Guidelinesに従う

### ビルド・テスト
- コード変更後は必ずビルドを実行して確認する
- 新機能には必ずユニットテストを書く（XCTest / Swift Testing）
- テストが通るまで次のステップに進まない

### セキュリティ
- APIキー・シークレットは絶対にコードにハードコードしない → Constants.swift の AWSConfig に集約
- ユーザー入力は必ずバリデーション・サニタイズする
- HTTP通信はHTTPSのみ。ATS例外は原則禁止

### ドキュメント
- 主要な設計判断を行った場合は docs/ 配下のドキュメントを更新する
- コミットメッセージは Conventional Commits 形式（feat:, fix:, refactor: 等）

## 🟡 推奨ルール（SHOULD）

- Apple Human Interface Guidelines（HIG）に準拠したUIを実装する
- Dynamic Type / Dark Mode / VoiceOver に対応する
- SF Symbols を積極的に使用する
- async-await を使ったリアクティブなデータフローを採用する
- Logger を使ったデバッグログを複雑な処理に入れる

## 🔵 プロジェクト固有の注意点

### カラースキーム
- Primary: #FF8C42（温かいオレンジ）
- Secondary: #FFD166（明るいイエロー）
- Accent: #F4845F（コーラル）
- Background: #FFF8F0（クリーム）
- TextPrimary: #5D4037（ブラウン系）
- Success: #FFB347（オレンジ系 - 緑は使用禁止）
- Error: #E57373（ソフトレッド）
- **カラールール**: 緑系の色（#XXXXXXでG値が突出するもの）は一切使用禁止。成功状態もオレンジ/イエロー系で表現する

### 投稿タイプ
- `light`: 今日あったいいこと（アイコン: sun.max.fill）
- `seed`: 世界にこうなってほしい（アイコン: sparkles）
- ※leafアイコンは緑を想起させるため使用禁止

### AWS連携
- 設定値は全て Constants.swift の AWSConfig に集約
- ドキュメント記載値は参考情報、実装時は必ずConstants参照

### iOS実装前提（iOS 17.0固定）
- Minimum Deployments: iOS 17.0
- @Observable マクロを使用（Observation framework）
- onChange(of:initial:) 使用可能
- NavigationStack 使用
- シミュレーターと実機でメモリ使用量に差があるため注意

### 認証（Cognito）実装ルール
- User Pool + SRP認証フロー
- トークン: ID Token（API認証）/ Access Token（Cognito操作）/ Refresh Token（更新用）
- Keychain保存: ID Token + Refresh Token
- トークン更新: 排他制御で単一フライト（同時多発リクエストの競合抑止）
- 401受信時: Refresh Token で更新 → 成功時リトライ（冪等なGETのみ）
- サインアウト時: Keychain全削除 + メモリキャッシュクリア

### 画像アップロードルール
- Info.plist: NSPhotoLibraryUsageDescription 必須
- HEIC → JPEG変換、圧縮率0.8
- EXIF（位置情報含む）は完全削除してからアップロード
- 長辺1080pxにリサイズ
- 並列アップロード: 最大2枚まで
- 失敗時: 3回までリトライ、それでも失敗なら該当画像のみスキップしてユーザーに通知
