import Foundation

struct Post: Identifiable, Codable {
    let id: String
    let userId: String
    let type: PostType
    var content: String
    var category: PostCategory
    var isVisible: Bool
    let createdAt: Date

    // v2: 画像・コメント・ブックマーク対応
    var imageUrls: [String]
    var commentCount: Int
    var isBookmarked: Bool

    var user: User?

    // デフォルト値付きイニシャライザ（既存コードとの互換性維持）
    init(
        id: String,
        userId: String,
        type: PostType,
        content: String,
        category: PostCategory,
        isVisible: Bool,
        createdAt: Date,
        imageUrls: [String] = [],
        commentCount: Int = 0,
        isBookmarked: Bool = false,
        user: User? = nil
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.content = content
        self.category = category
        self.isVisible = isVisible
        self.createdAt = createdAt
        self.imageUrls = imageUrls
        self.commentCount = commentCount
        self.isBookmarked = isBookmarked
        self.user = user
    }

    enum PostType: String, Codable, CaseIterable {
        case goodThing = "good_thing"
        case idealWorld = "ideal_world"

        var displayName: String {
            switch self {
            case .goodThing:
                return AppStrings.goodThing  // 今日あったいいこと
            case .idealWorld:
                return AppStrings.idealWorld  // 世界にこうなってほしい
            }
        }

        var icon: String {
            switch self {
            case .goodThing:
                return "sun.max.fill"
            case .idealWorld:
                return "sparkles"  // v2: leaf.fillは緑を想起させるため禁止
            }
        }
    }
}

extension Post {
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    static let mockGoodThings: [Post] = [
        Post(
            id: UUID().uuidString,
            userId: "user1",
            type: .goodThing,
            content: "今日友達とカフェに行って楽しかった！久しぶりに会えて嬉しかったな",
            category: .friends,
            isVisible: true,
            createdAt: Date().addingTimeInterval(-120),
            imageUrls: [],
            commentCount: 3,
            isBookmarked: true,
            user: .mock
        ),
        Post(
            id: UUID().uuidString,
            userId: "user2",
            type: .goodThing,
            content: "テストで目標点取れた！頑張った甲斐があった",
            category: .achievement,
            isVisible: true,
            createdAt: Date().addingTimeInterval(-900),
            imageUrls: [],
            commentCount: 1,
            isBookmarked: false,
            user: User(id: "user2", nickname: "ユーザーB", email: "b@example.com", authProvider: .apple, bio: nil, avatarURL: nil, createdAt: Date(), updatedAt: Date())
        ),
        Post(
            id: UUID().uuidString,
            userId: "user3",
            type: .goodThing,
            content: "お母さんが作ってくれたご飯が美味しかった",
            category: .family,
            isVisible: true,
            createdAt: Date().addingTimeInterval(-3600),
            imageUrls: [],
            commentCount: 5,
            isBookmarked: false,
            user: User(id: "user3", nickname: "ユーザーC", email: "c@example.com", authProvider: .google, bio: nil, avatarURL: nil, createdAt: Date(), updatedAt: Date())
        )
    ]

    static let mockIdealWorld: [Post] = [
        Post(
            id: UUID().uuidString,
            userId: "user1",
            type: .idealWorld,
            content: "みんなが優しくできる世界になって欲しい",
            category: .community,
            isVisible: true,
            createdAt: Date().addingTimeInterval(-300),
            imageUrls: [],
            commentCount: 8,
            isBookmarked: true,
            user: .mock
        ),
        Post(
            id: UUID().uuidString,
            userId: "user4",
            type: .idealWorld,
            content: "環境問題がなくなる未来が来て欲しい",
            category: .environment,
            isVisible: true,
            createdAt: Date().addingTimeInterval(-1800),
            imageUrls: [],
            commentCount: 2,
            isBookmarked: false,
            user: User(id: "user4", nickname: "ユーザーD", email: "d@example.com", authProvider: .email, bio: nil, avatarURL: nil, createdAt: Date(), updatedAt: Date())
        )
    ]
}
