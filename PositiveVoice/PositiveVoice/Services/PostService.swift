import Foundation

// AWS Amplifyは後から追加します
// 現在はモックモードで動作します

protocol PostServiceProtocol {
    func createPost(content: String, type: Post.PostType) async throws -> Post
    func fetchPosts(type: Post.PostType, sortOrder: HomeViewModel.SortOrder, limit: Int) async throws -> [Post]
    func fetchPost(id: String) async throws -> Post?
    func fetchSimilarPosts(postId: String, limit: Int) async throws -> [Post]
    func fetchMyPosts(userId: String) async throws -> [Post]
    func searchPosts(query: String, type: Post.PostType?, category: PostCategory?) async throws -> [Post]
    func deletePost(id: String) async throws
}

class PostService: PostServiceProtocol {
    static let shared = PostService()

    private init() {}

    // MARK: - Create Post (Mock)

    func createPost(content: String, type: Post.PostType) async throws -> Post {
        try await Task.sleep(nanoseconds: 500_000_000)

        let post = Post(
            id: UUID().uuidString,
            userId: "mock_user",
            type: type,
            content: content,
            category: type == .goodThing ? .other : .community,
            isVisible: true,
            createdAt: Date(),
            user: User.mock
        )

        print("PostService: Mock created post")
        return post
    }

    // MARK: - Fetch Posts (Mock)

    func fetchPosts(type: Post.PostType, sortOrder: HomeViewModel.SortOrder, limit: Int = 20) async throws -> [Post] {
        try await Task.sleep(nanoseconds: 300_000_000)

        let posts = type == .goodThing ? Post.mockGoodThings : Post.mockIdealWorld

        if sortOrder == .recommended {
            return posts.shuffled()
        }
        return posts
    }

    // MARK: - Fetch Single Post (Mock)

    func fetchPost(id: String) async throws -> Post? {
        try await Task.sleep(nanoseconds: 200_000_000)
        return Post.mockGoodThings.first
    }

    // MARK: - Fetch Similar Posts (Mock)

    func fetchSimilarPosts(postId: String, limit: Int = 5) async throws -> [Post] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return Array(Post.mockGoodThings.prefix(limit))
    }

    // MARK: - Fetch My Posts (Mock)

    func fetchMyPosts(userId: String) async throws -> [Post] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return Post.mockGoodThings
    }

    // MARK: - Search Posts (Mock)

    func searchPosts(query: String, type: Post.PostType?, category: PostCategory?) async throws -> [Post] {
        try await Task.sleep(nanoseconds: 300_000_000)

        var posts = Post.mockGoodThings + Post.mockIdealWorld

        if let type = type {
            posts = posts.filter { $0.type == type }
        }

        if let category = category {
            posts = posts.filter { $0.category == category }
        }

        if !query.isEmpty {
            posts = posts.filter { $0.content.localizedCaseInsensitiveContains(query) }
        }

        return posts
    }

    // MARK: - Delete Post (Mock)

    func deletePost(id: String) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
        print("PostService: Mock deleted post \(id)")
    }
}

// MARK: - Response Models

struct PostsResponse: Codable {
    let posts: [Post]
    let nextToken: String?
}
