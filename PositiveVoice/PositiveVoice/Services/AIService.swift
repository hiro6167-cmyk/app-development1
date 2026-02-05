import Foundation

// AWS Amplifyは後から追加します
// 現在はモックモードで動作します

protocol AIServiceProtocol {
    func classifyPost(content: String, type: Post.PostType) async throws -> PostCategory
    func detectInappropriateContent(content: String) async throws -> Bool
    func generateEmbedding(content: String) async throws -> [Float]
}

class AIService: AIServiceProtocol {
    static let shared = AIService()

    private init() {}

    // MARK: - Classify Post (Mock)

    /// AIを使用して投稿を適切なカテゴリに分類（モック）
    func classifyPost(content: String, type: Post.PostType) async throws -> PostCategory {
        try await Task.sleep(nanoseconds: 200_000_000)

        // 簡易的なキーワードベースの分類
        let lowercased = content.lowercased()

        if type == .goodThing {
            if lowercased.contains("友達") || lowercased.contains("友人") {
                return .friends
            } else if lowercased.contains("テスト") || lowercased.contains("勉強") || lowercased.contains("学校") {
                return .school
            } else if lowercased.contains("家族") || lowercased.contains("母") || lowercased.contains("父") {
                return .family
            } else if lowercased.contains("ご飯") || lowercased.contains("美味し") || lowercased.contains("食べ") {
                return .food
            } else if lowercased.contains("できた") || lowercased.contains("成功") || lowercased.contains("達成") {
                return .achievement
            }
            return .other
        } else {
            if lowercased.contains("環境") || lowercased.contains("自然") {
                return .environment
            } else if lowercased.contains("平和") || lowercased.contains("安全") {
                return .peace
            } else if lowercased.contains("教育") || lowercased.contains("学校") {
                return .education
            }
            return .community
        }
    }

    // MARK: - Detect Inappropriate Content (Mock)

    /// AIを使用して不適切なコンテンツを検出（モック）
    func detectInappropriateContent(content: String) async throws -> Bool {
        try await Task.sleep(nanoseconds: 100_000_000)
        // モック: 常に適切と判定
        return false
    }

    // MARK: - Generate Embedding (Mock)

    /// 類似検索用のベクトル埋め込みを生成（モック）
    func generateEmbedding(content: String) async throws -> [Float] {
        try await Task.sleep(nanoseconds: 100_000_000)
        // モック: ランダムなベクトルを返す
        return (0..<128).map { _ in Float.random(in: -1...1) }
    }

    // MARK: - Sentiment Analysis (Mock)

    /// 感情分析（モック）
    func analyzeSentiment(content: String) async throws -> SentimentResult {
        try await Task.sleep(nanoseconds: 100_000_000)
        return SentimentResult(
            sentiment: "POSITIVE",
            positiveScore: 0.8,
            negativeScore: 0.05,
            neutralScore: 0.1,
            mixedScore: 0.05
        )
    }
}

// MARK: - Response Models

struct ClassificationResponse: Codable {
    let category: String
    let confidence: Float
}

struct ModerationResponse: Codable {
    let isInappropriate: Bool
    let reason: String?
    let confidence: Float
}

struct EmbeddingResponse: Codable {
    let embedding: [Float]
}

struct SentimentResult: Codable {
    let sentiment: String
    let positiveScore: Float
    let negativeScore: Float
    let neutralScore: Float
    let mixedScore: Float
}
