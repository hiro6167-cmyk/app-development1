import Foundation

/// ブックマークモデル（v2）
struct Bookmark: Codable {
    let userId: String
    let postId: String
    let createdAt: Date

    init(
        userId: String,
        postId: String,
        createdAt: Date = Date()
    ) {
        self.userId = userId
        self.postId = postId
        self.createdAt = createdAt
    }
}
