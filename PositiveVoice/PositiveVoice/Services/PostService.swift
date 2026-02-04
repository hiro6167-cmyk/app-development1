import Foundation
import Amplify

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

    private let apiName = "PositiveVoiceAPI"

    private init() {}

    // MARK: - Create Post

    func createPost(content: String, type: Post.PostType) async throws -> Post {
        let body: [String: Any] = [
            "content": content,
            "type": type.rawValue
        ]

        let request = RESTRequest(
            apiName: apiName,
            path: "/posts",
            body: try JSONSerialization.data(withJSONObject: body)
        )

        let data = try await Amplify.API.post(request: request)
        let post = try JSONDecoder().decode(Post.self, from: data)

        return post
    }

    // MARK: - Fetch Posts

    func fetchPosts(type: Post.PostType, sortOrder: HomeViewModel.SortOrder, limit: Int = 20) async throws -> [Post] {
        let queryParams = [
            "type": type.rawValue,
            "sort": sortOrder.rawValue,
            "limit": String(limit)
        ]

        let request = RESTRequest(
            apiName: apiName,
            path: "/posts",
            queryParameters: queryParams
        )

        let data = try await Amplify.API.get(request: request)
        let response = try JSONDecoder().decode(PostsResponse.self, from: data)

        return response.posts
    }

    // MARK: - Fetch Single Post

    func fetchPost(id: String) async throws -> Post? {
        let request = RESTRequest(
            apiName: apiName,
            path: "/posts/\(id)"
        )

        let data = try await Amplify.API.get(request: request)
        let post = try JSONDecoder().decode(Post.self, from: data)

        return post
    }

    // MARK: - Fetch Similar Posts

    func fetchSimilarPosts(postId: String, limit: Int = 5) async throws -> [Post] {
        let queryParams = [
            "limit": String(limit)
        ]

        let request = RESTRequest(
            apiName: apiName,
            path: "/posts/\(postId)/similar",
            queryParameters: queryParams
        )

        let data = try await Amplify.API.get(request: request)
        let response = try JSONDecoder().decode(PostsResponse.self, from: data)

        return response.posts
    }

    // MARK: - Fetch My Posts

    func fetchMyPosts(userId: String) async throws -> [Post] {
        let queryParams = [
            "userId": userId
        ]

        let request = RESTRequest(
            apiName: apiName,
            path: "/posts/me",
            queryParameters: queryParams
        )

        let data = try await Amplify.API.get(request: request)
        let response = try JSONDecoder().decode(PostsResponse.self, from: data)

        return response.posts
    }

    // MARK: - Search Posts

    func searchPosts(query: String, type: Post.PostType?, category: PostCategory?) async throws -> [Post] {
        var queryParams: [String: String] = [:]

        if !query.isEmpty {
            queryParams["q"] = query
        }
        if let type = type {
            queryParams["type"] = type.rawValue
        }
        if let category = category {
            queryParams["category"] = category.rawValue
        }

        let request = RESTRequest(
            apiName: apiName,
            path: "/posts/search",
            queryParameters: queryParams
        )

        let data = try await Amplify.API.get(request: request)
        let response = try JSONDecoder().decode(PostsResponse.self, from: data)

        return response.posts
    }

    // MARK: - Delete Post

    func deletePost(id: String) async throws {
        let request = RESTRequest(
            apiName: apiName,
            path: "/posts/\(id)"
        )

        _ = try await Amplify.API.delete(request: request)
    }
}

// MARK: - Response Models

struct PostsResponse: Codable {
    let posts: [Post]
    let nextToken: String?
}
