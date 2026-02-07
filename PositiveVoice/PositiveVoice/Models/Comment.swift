import Foundation

/// コメントモデル（v2）
struct Comment: Identifiable, Codable {
    let id: String
    let postId: String
    let userId: String
    let content: String
    let createdAt: Date

    var user: User?

    init(
        id: String,
        postId: String,
        userId: String,
        content: String,
        createdAt: Date,
        user: User? = nil
    ) {
        self.id = id
        self.postId = postId
        self.userId = userId
        self.content = content
        self.createdAt = createdAt
        self.user = user
    }
}

extension Comment {
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    static let mockComments: [Comment] = [
        Comment(
            id: UUID().uuidString,
            postId: "post1",
            userId: "user2",
            content: "すごくいいですね！私も同じ経験があります",
            createdAt: Date().addingTimeInterval(-60),
            user: User(id: "user2", nickname: "ユーザーB", email: "b@example.com", authProvider: .apple, bio: nil, avatarURL: nil, createdAt: Date(), updatedAt: Date())
        ),
        Comment(
            id: UUID().uuidString,
            postId: "post1",
            userId: "user3",
            content: "素敵！共感します ✨",
            createdAt: Date().addingTimeInterval(-300),
            user: User(id: "user3", nickname: "ユーザーC", email: "c@example.com", authProvider: .google, bio: nil, avatarURL: nil, createdAt: Date(), updatedAt: Date())
        ),
        Comment(
            id: UUID().uuidString,
            postId: "post1",
            userId: "user4",
            content: "私も頑張ろうって思えました！",
            createdAt: Date().addingTimeInterval(-1800),
            user: User(id: "user4", nickname: "ユーザーD", email: "d@example.com", authProvider: .email, bio: nil, avatarURL: nil, createdAt: Date(), updatedAt: Date())
        )
    ]
}
