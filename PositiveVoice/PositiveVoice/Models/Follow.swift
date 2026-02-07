import Foundation

/// フォロー関係モデル（v2）
struct Follow: Codable {
    let followerId: String
    let followeeId: String
    let createdAt: Date

    init(
        followerId: String,
        followeeId: String,
        createdAt: Date = Date()
    ) {
        self.followerId = followerId
        self.followeeId = followeeId
        self.createdAt = createdAt
    }
}

/// ユーザー詳細情報（フォロー数など）
struct UserProfile: Identifiable, Codable {
    let id: String
    var nickname: String
    var bio: String?
    var avatarURL: String?
    var postCount: Int
    var followerCount: Int
    var followingCount: Int
    var isFollowing: Bool
    let createdAt: Date

    init(
        id: String,
        nickname: String,
        bio: String? = nil,
        avatarURL: String? = nil,
        postCount: Int = 0,
        followerCount: Int = 0,
        followingCount: Int = 0,
        isFollowing: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.nickname = nickname
        self.bio = bio
        self.avatarURL = avatarURL
        self.postCount = postCount
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.isFollowing = isFollowing
        self.createdAt = createdAt
    }
}

extension UserProfile {
    static let mock = UserProfile(
        id: "user1",
        nickname: "ユーザーA",
        bio: "プログラミングが好きな大学生です",
        avatarURL: nil,
        postCount: 15,
        followerCount: 42,
        followingCount: 28,
        isFollowing: false,
        createdAt: Date()
    )

    static let mockOther = UserProfile(
        id: "user2",
        nickname: "ユーザーB",
        bio: "毎日ポジティブに！",
        avatarURL: nil,
        postCount: 23,
        followerCount: 156,
        followingCount: 89,
        isFollowing: true,
        createdAt: Date()
    )
}
