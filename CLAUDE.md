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
- Background: #FFF8F0（クリーム）
- テキスト: #5D4037（ブラウン系）
- グリーン系は使用しない

### 投稿タイプ
- `light`: 今日あったいいこと
- `seed`: 世界にこうなってほしい

### AWS連携
- API Endpoint: https://2qti95chy9.execute-api.ap-northeast-1.amazonaws.com/dev
- リージョン: ap-northeast-1（東京）
- 認証: Cognito（メール/パスワード）

### 発見された注意点
- NavigationStack は iOS 16+、onChange(of:initial:) は iOS 17+ が必要
- Minimum Deployments: iOS 17.0
- シミュレーターと実機でメモリ使用量に差があるため注意
