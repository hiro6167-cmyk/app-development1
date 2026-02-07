import Foundation

/// コメントサービス（v2）
protocol CommentServiceProtocol {
    func fetchComments(postId: String) async throws -> [Comment]
    func createComment(postId: String, content: String) async throws -> Comment
    func deleteComment(id: String) async throws
}

class CommentService: CommentServiceProtocol {
    static let shared = CommentService()

    private init() {}

    // MARK: - Fetch Comments (Mock)

    func fetchComments(postId: String) async throws -> [Comment] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return Comment.mockComments
    }

    // MARK: - Create Comment (Mock)

    func createComment(postId: String, content: String) async throws -> Comment {
        try await Task.sleep(nanoseconds: 500_000_000)

        let comment = Comment(
            id: UUID().uuidString,
            postId: postId,
            userId: "current_user",
            content: content,
            createdAt: Date(),
            user: User.mock
        )

        print("CommentService: Mock created comment")
        return comment
    }

    // MARK: - Delete Comment (Mock)

    func deleteComment(id: String) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
        print("CommentService: Mock deleted comment \(id)")
    }
}
