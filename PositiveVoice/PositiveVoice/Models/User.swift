import Foundation

struct User: Identifiable, Codable {
    let id: String
    var nickname: String
    var email: String
    var authProvider: AuthProvider
    var bio: String?
    var avatarURL: String?
    let createdAt: Date
    var updatedAt: Date

    enum AuthProvider: String, Codable {
        case email
        case apple
        case google
    }
}

extension User {
    static let mock = User(
        id: UUID().uuidString,
        nickname: "ユーザーA",
        email: "user@example.com",
        authProvider: .email,
        bio: "プログラミングが好きな大学生です",
        avatarURL: nil,
        createdAt: Date(),
        updatedAt: Date()
    )
}
