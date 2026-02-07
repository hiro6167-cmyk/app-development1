import Foundation
import SwiftUI

/// プロフィール用ViewModel（v2）
@MainActor
class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var myPosts: [Post] = []
    @Published var bookmarkedPosts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var selectedTab: ProfileTab = .posts
    @Published var errorMessage: String?

    enum ProfileTab: String, CaseIterable {
        case posts = "投稿"
        case bookmarks = "ブックマーク"
    }

    private let postService = PostService.shared
    private let bookmarkService = BookmarkService.shared

    init() {}

    func loadMyProfile() async {
        isLoading = true

        // モック: 自分のプロフィール
        userProfile = UserProfile.mock

        do {
            myPosts = try await postService.fetchMyPosts(userId: "current_user")
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadBookmarks() async {
        do {
            bookmarkedPosts = try await bookmarkService.fetchBookmarkedPosts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshCurrentTab() async {
        switch selectedTab {
        case .posts:
            await loadMyProfile()
        case .bookmarks:
            await loadBookmarks()
        }
    }
}

/// 他ユーザープロフィール用ViewModel（v2）
@MainActor
class UserProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var posts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var isFollowLoading: Bool = false
    @Published var errorMessage: String?

    private let userId: String
    private let postService = PostService.shared
    private let followService = FollowService.shared

    var isFollowing: Bool {
        followService.isFollowing(userId)
    }

    init(userId: String) {
        self.userId = userId
    }

    func loadProfile() async {
        isLoading = true

        do {
            userProfile = try await followService.fetchUserProfile(userId: userId)
            posts = try await postService.fetchMyPosts(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func toggleFollow() async {
        isFollowLoading = true

        do {
            try await followService.toggleFollow(userId: userId)
            // プロフィールを再取得してフォロワー数を更新
            userProfile = try await followService.fetchUserProfile(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }

        isFollowLoading = false
    }
}

/// フォロー一覧用ViewModel（v2）
@MainActor
class FollowListViewModel: ObservableObject {
    @Published var users: [UserProfile] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    enum ListType {
        case followers
        case following
    }

    private let userId: String
    private let listType: ListType
    private let followService = FollowService.shared

    init(userId: String, listType: ListType) {
        self.userId = userId
        self.listType = listType
    }

    var title: String {
        switch listType {
        case .followers: return "フォロワー"
        case .following: return "フォロー中"
        }
    }

    func loadUsers() async {
        isLoading = true

        do {
            switch listType {
            case .followers:
                users = try await followService.fetchFollowers(userId: userId)
            case .following:
                users = try await followService.fetchFollowing(userId: userId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func toggleFollow(for user: UserProfile) async {
        do {
            try await followService.toggleFollow(userId: user.id)
            // リストを再取得
            await loadUsers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
