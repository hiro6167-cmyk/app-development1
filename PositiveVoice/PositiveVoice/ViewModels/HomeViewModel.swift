import SwiftUI

class HomeViewModel: ObservableObject {
    @Published var selectedPostType: Post.PostType = .goodThing
    @Published var sortOrder: SortOrder = .newest
    @Published var posts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    enum SortOrder: String, CaseIterable {
        case newest = "newest"
        case recommended = "recommended"

        var displayName: String {
            switch self {
            case .newest: return "新着順"
            case .recommended: return "おすすめ順"
            }
        }
    }

    init() {
        loadPosts()
    }

    func loadPosts() {
        isLoading = true

        // TODO: Fetch from AWS API
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
            switch self.selectedPostType {
            case .goodThing:
                self.posts = Post.mockGoodThings
            case .idealWorld:
                self.posts = Post.mockIdealWorld
            }

            if self.sortOrder == .recommended {
                self.posts.shuffle()
            }
        }
    }

    func refreshPosts() {
        loadPosts()
    }

    func selectPostType(_ type: Post.PostType) {
        selectedPostType = type
        loadPosts()
    }

    func setSortOrder(_ order: SortOrder) {
        sortOrder = order
        loadPosts()
    }
}
