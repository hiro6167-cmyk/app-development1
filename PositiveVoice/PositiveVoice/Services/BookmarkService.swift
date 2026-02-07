import Foundation
import SwiftUI

/// ブックマークサービス（v2）
/// 設計書 8.1 のキャッシュ整合方針に準拠
@Observable
class BookmarkService {
    static let shared = BookmarkService()

    private(set) var bookmarkedPostIds: Set<String> = []
    private(set) var bookmarkedPosts: [Post] = []
    private(set) var isLoading: Bool = false

    private init() {
        loadFromCache()
    }

    // MARK: - Cache Keys

    private enum CacheKeys {
        static let bookmarkedPostIds = "bookmarked_post_ids"
        static let bookmarksSyncedAt = "bookmarks_synced_at"
    }

    // MARK: - Public Methods

    /// サーバーと同期
    func syncWithServer() async {
        // TODO: 実際のAPI実装時に有効化
        // do {
        //     let serverBookmarks = try await apiClient.get("/bookmarks")
        //     let serverIds = Set(serverBookmarks.map { $0.postId })
        //     bookmarkedPostIds = serverIds
        //     saveToCache()
        // } catch {
        //     print("Bookmark sync failed: \(error)")
        // }

        // モック: 現在のキャッシュをそのまま使用
        try? await Task.sleep(nanoseconds: 300_000_000)
    }

    /// ブックマーク状態をトグル（楽観的更新）
    func toggle(_ postId: String) async throws {
        let isCurrentlyBookmarked = bookmarkedPostIds.contains(postId)

        // 楽観的更新
        if isCurrentlyBookmarked {
            bookmarkedPostIds.remove(postId)
            bookmarkedPosts.removeAll { $0.id == postId }
        } else {
            bookmarkedPostIds.insert(postId)
        }
        saveToCache()

        // TODO: 実際のAPI呼び出し
        do {
            try await Task.sleep(nanoseconds: 200_000_000) // モック遅延
            // if isCurrentlyBookmarked {
            //     try await apiClient.delete("/bookmarks/\(postId)")
            // } else {
            //     try await apiClient.post("/bookmarks/\(postId)")
            // }
        } catch {
            // ロールバック
            if isCurrentlyBookmarked {
                bookmarkedPostIds.insert(postId)
            } else {
                bookmarkedPostIds.remove(postId)
            }
            saveToCache()
            throw error
        }
    }

    /// ブックマーク済みかどうか
    func isBookmarked(_ postId: String) -> Bool {
        bookmarkedPostIds.contains(postId)
    }

    /// ブックマーク一覧を取得
    func fetchBookmarkedPosts() async throws -> [Post] {
        isLoading = true
        defer { isLoading = false }

        try await Task.sleep(nanoseconds: 300_000_000)

        // モック: ブックマーク済みの投稿を返す
        let allPosts = Post.mockGoodThings + Post.mockIdealWorld
        bookmarkedPosts = allPosts.filter { bookmarkedPostIds.contains($0.id) || $0.isBookmarked }

        return bookmarkedPosts
    }

    // MARK: - Private Methods

    private func loadFromCache() {
        if let ids = UserDefaults.standard.array(forKey: CacheKeys.bookmarkedPostIds) as? [String] {
            bookmarkedPostIds = Set(ids)
        }
    }

    private func saveToCache() {
        UserDefaults.standard.set(Array(bookmarkedPostIds), forKey: CacheKeys.bookmarkedPostIds)
        UserDefaults.standard.set(Date(), forKey: CacheKeys.bookmarksSyncedAt)
    }

    /// ログアウト時にキャッシュをクリア
    func clearCache() {
        bookmarkedPostIds.removeAll()
        bookmarkedPosts.removeAll()
        UserDefaults.standard.removeObject(forKey: CacheKeys.bookmarkedPostIds)
        UserDefaults.standard.removeObject(forKey: CacheKeys.bookmarksSyncedAt)
    }
}
