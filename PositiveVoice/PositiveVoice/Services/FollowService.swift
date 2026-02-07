import Foundation
import SwiftUI

/// フォローサービス（v2）
@Observable
class FollowService {
    static let shared = FollowService()

    private(set) var followingUserIds: Set<String> = []
    private(set) var isLoading: Bool = false

    private init() {
        loadFromCache()
    }

    // MARK: - Cache Keys

    private enum CacheKeys {
        static let followingUserIds = "following_user_ids"
    }

    // MARK: - Public Methods

    /// フォロー/アンフォロー トグル
    func toggleFollow(userId: String) async throws {
        let isCurrentlyFollowing = followingUserIds.contains(userId)

        // 楽観的更新
        if isCurrentlyFollowing {
            followingUserIds.remove(userId)
        } else {
            followingUserIds.insert(userId)
        }
        saveToCache()

        // TODO: 実際のAPI呼び出し
        do {
            try await Task.sleep(nanoseconds: 300_000_000) // モック遅延
        } catch {
            // ロールバック
            if isCurrentlyFollowing {
                followingUserIds.insert(userId)
            } else {
                followingUserIds.remove(userId)
            }
            saveToCache()
            throw error
        }
    }

    /// フォロー中かどうか
    func isFollowing(_ userId: String) -> Bool {
        followingUserIds.contains(userId)
    }

    /// フォロワー一覧を取得
    func fetchFollowers(userId: String) async throws -> [UserProfile] {
        isLoading = true
        defer { isLoading = false }

        try await Task.sleep(nanoseconds: 300_000_000)

        // モックデータ
        return [UserProfile.mock, UserProfile.mockOther]
    }

    /// フォロー中一覧を取得
    func fetchFollowing(userId: String) async throws -> [UserProfile] {
        isLoading = true
        defer { isLoading = false }

        try await Task.sleep(nanoseconds: 300_000_000)

        // モックデータ
        return [UserProfile.mockOther]
    }

    /// ユーザープロフィールを取得
    func fetchUserProfile(userId: String) async throws -> UserProfile {
        try await Task.sleep(nanoseconds: 300_000_000)

        // モック: 他ユーザー用
        var profile = UserProfile.mockOther
        profile = UserProfile(
            id: userId,
            nickname: profile.nickname,
            bio: profile.bio,
            avatarURL: profile.avatarURL,
            postCount: profile.postCount,
            followerCount: profile.followerCount,
            followingCount: profile.followingCount,
            isFollowing: isFollowing(userId),
            createdAt: profile.createdAt
        )
        return profile
    }

    // MARK: - Private Methods

    private func loadFromCache() {
        if let ids = UserDefaults.standard.array(forKey: CacheKeys.followingUserIds) as? [String] {
            followingUserIds = Set(ids)
        }
    }

    private func saveToCache() {
        UserDefaults.standard.set(Array(followingUserIds), forKey: CacheKeys.followingUserIds)
    }

    /// ログアウト時にキャッシュをクリア
    func clearCache() {
        followingUserIds.removeAll()
        UserDefaults.standard.removeObject(forKey: CacheKeys.followingUserIds)
    }
}
