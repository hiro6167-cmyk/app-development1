import Foundation
import Amplify

protocol AIServiceProtocol {
    func classifyPost(content: String, type: Post.PostType) async throws -> PostCategory
    func detectInappropriateContent(content: String) async throws -> Bool
    func generateEmbedding(content: String) async throws -> [Float]
}

class AIService: AIServiceProtocol {
    static let shared = AIService()

    private let apiName = "PositiveVoiceAPI"

    private init() {}

    // MARK: - Classify Post

    /// AIを使用して投稿を適切なカテゴリに分類
    func classifyPost(content: String, type: Post.PostType) async throws -> PostCategory {
        let body: [String: Any] = [
            "content": content,
            "type": type.rawValue
        ]

        let request = RESTRequest(
            apiName: apiName,
            path: "/ai/classify",
            body: try JSONSerialization.data(withJSONObject: body)
        )

        let data = try await Amplify.API.post(request: request)
        let response = try JSONDecoder().decode(ClassificationResponse.self, from: data)

        return PostCategory(rawValue: response.category) ?? .other
    }

    // MARK: - Detect Inappropriate Content

    /// AIを使用して不適切なコンテンツを検出
    func detectInappropriateContent(content: String) async throws -> Bool {
        let body: [String: Any] = [
            "content": content
        ]

        let request = RESTRequest(
            apiName: apiName,
            path: "/ai/moderate",
            body: try JSONSerialization.data(withJSONObject: body)
        )

        let data = try await Amplify.API.post(request: request)
        let response = try JSONDecoder().decode(ModerationResponse.self, from: data)

        return response.isInappropriate
    }

    // MARK: - Generate Embedding

    /// 類似検索用のベクトル埋め込みを生成
    func generateEmbedding(content: String) async throws -> [Float] {
        let body: [String: Any] = [
            "content": content
        ]

        let request = RESTRequest(
            apiName: apiName,
            path: "/ai/embedding",
            body: try JSONSerialization.data(withJSONObject: body)
        )

        let data = try await Amplify.API.post(request: request)
        let response = try JSONDecoder().decode(EmbeddingResponse.self, from: data)

        return response.embedding
    }

    // MARK: - Sentiment Analysis

    /// 感情分析（ポジティブ度の測定）
    func analyzeSentiment(content: String) async throws -> SentimentResult {
        let body: [String: Any] = [
            "content": content
        ]

        let request = RESTRequest(
            apiName: apiName,
            path: "/ai/sentiment",
            body: try JSONSerialization.data(withJSONObject: body)
        )

        let data = try await Amplify.API.post(request: request)
        let response = try JSONDecoder().decode(SentimentResult.self, from: data)

        return response
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
    let sentiment: String // "POSITIVE", "NEGATIVE", "NEUTRAL", "MIXED"
    let positiveScore: Float
    let negativeScore: Float
    let neutralScore: Float
    let mixedScore: Float
}
