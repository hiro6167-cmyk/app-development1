import Foundation

// MARK: - Post Service Protocol

protocol PostServiceProtocol {
    func createPost(content: String, type: Post.PostType, category: PostCategory?, imageUrls: [String]) async throws -> Post
    func fetchPosts(type: Post.PostType, sortOrder: HomeViewModel.SortOrder, limit: Int) async throws -> [Post]
    func fetchPost(id: String) async throws -> Post?
    func fetchSimilarPosts(postId: String, limit: Int) async throws -> [Post]
    func fetchMyPosts(userId: String) async throws -> [Post]
    func searchPosts(query: String, type: Post.PostType?, category: PostCategory?) async throws -> [Post]
    func deletePost(id: String) async throws
}

// MARK: - Post Service Implementation

class PostService: PostServiceProtocol {
    static let shared = PostService()

    private let apiClient = APIClient.shared

    private init() {}

    // MARK: - Create Post

    func createPost(content: String, type: Post.PostType, category: PostCategory? = nil, imageUrls: [String] = []) async throws -> Post {
        let request = CreatePostRequest(
            content: content,
            type: type.rawValue,
            category: category?.rawValue,
            imageUrls: imageUrls.isEmpty ? nil : imageUrls
        )

        let response: CreatePostResponse = try await apiClient.post("/posts", body: request)
        return response.toPost()
    }

    // MARK: - Fetch Posts

    func fetchPosts(type: Post.PostType, sortOrder: HomeViewModel.SortOrder, limit: Int = 20) async throws -> [Post] {
        var queryItems = [
            URLQueryItem(name: "type", value: type.rawValue),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        if sortOrder == .recommended {
            queryItems.append(URLQueryItem(name: "sort", value: "recommended"))
        } else {
            queryItems.append(URLQueryItem(name: "sort", value: "latest"))
        }

        let response: PostsListResponse = try await apiClient.get("/posts", queryItems: queryItems)
        return response.posts.map { $0.toPost() }
    }

    // MARK: - Fetch Single Post

    func fetchPost(id: String) async throws -> Post? {
        let response: PostResponse = try await apiClient.get("/posts/\(id)")
        return response.toPost()
    }

    // MARK: - Fetch Similar Posts

    func fetchSimilarPosts(postId: String, limit: Int = 5) async throws -> [Post] {
        let queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        let response: PostsListResponse = try await apiClient.get("/posts/\(postId)/similar", queryItems: queryItems)
        return response.posts.map { $0.toPost() }
    }

    // MARK: - Fetch My Posts

    func fetchMyPosts(userId: String) async throws -> [Post] {
        let response: PostsListResponse = try await apiClient.get("/posts/me")
        return response.posts.map { $0.toPost() }
    }

    // MARK: - Search Posts

    func searchPosts(query: String, type: Post.PostType?, category: PostCategory?) async throws -> [Post] {
        var queryItems = [URLQueryItem]()

        if !query.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }

        if let type = type {
            queryItems.append(URLQueryItem(name: "type", value: type.rawValue))
        }

        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category.rawValue))
        }

        let response: PostsListResponse = try await apiClient.get("/posts/search", queryItems: queryItems)
        return response.posts.map { $0.toPost() }
    }

    // MARK: - Delete Post

    func deletePost(id: String) async throws {
        try await apiClient.delete("/posts/\(id)")
        print("PostService: Deleted post \(id)")
    }
}

// MARK: - Request Models

private struct CreatePostRequest: Encodable {
    let content: String
    let type: String
    let category: String?
    let imageUrls: [String]?
}

// MARK: - Response Models

private struct PostsListResponse: Decodable {
    let posts: [PostResponse]
    let nextToken: String?
}

private struct CreatePostResponse: Decodable {
    let postId: String
    let userId: String
    let type: String
    let content: String
    let category: String?
    let imageUrls: [String]?
    let isVisible: Bool
    let createdAt: String
    let user: UserResponse?

    func toPost() -> Post {
        Post(
            id: postId,
            userId: userId,
            type: Post.PostType(rawValue: type) ?? .goodThing,
            content: content,
            category: PostCategory(rawValue: category ?? "") ?? .other,
            imageUrls: imageUrls ?? [],
            isVisible: isVisible,
            createdAt: ISO8601DateFormatter().date(from: createdAt) ?? Date(),
            user: user?.toUser()
        )
    }
}

private struct PostResponse: Decodable {
    let postId: String
    let userId: String
    let type: String
    let content: String
    let category: String?
    let imageUrls: [String]?
    let isVisible: Bool
    let createdAt: String
    let user: UserResponse?
    let commentCount: Int?
    let isBookmarked: Bool?

    func toPost() -> Post {
        Post(
            id: postId,
            userId: userId,
            type: Post.PostType(rawValue: type) ?? .goodThing,
            content: content,
            category: PostCategory(rawValue: category ?? "") ?? .other,
            imageUrls: imageUrls ?? [],
            isVisible: isVisible,
            createdAt: ISO8601DateFormatter().date(from: createdAt) ?? Date(),
            user: user?.toUser(),
            commentCount: commentCount ?? 0,
            isBookmarked: isBookmarked ?? false
        )
    }
}

private struct UserResponse: Decodable {
    let userId: String
    let email: String?
    let nickname: String?
    let avatarURL: String?
    let bio: String?

    func toUser() -> User {
        User(
            id: userId,
            nickname: nickname ?? "匿名",
            email: email ?? "",
            authProvider: .email,
            bio: bio,
            avatarURL: avatarURL,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Legacy Response Model (for compatibility)

struct PostsResponse: Codable {
    let posts: [Post]
    let nextToken: String?
}
