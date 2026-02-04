import SwiftUI

class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedPostType: Post.PostType = .goodThing
    @Published var selectedCategory: PostCategory?
    @Published var searchResults: [Post] = []
    @Published var isSearching: Bool = false

    var categories: [PostCategory] {
        PostCategory.categories(for: selectedPostType)
    }

    func search() {
        guard !searchText.isEmpty || selectedCategory != nil else {
            searchResults = []
            return
        }

        isSearching = true

        // TODO: Search via AWS API
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isSearching = false

            let allPosts = self.selectedPostType == .goodThing
                ? Post.mockGoodThings
                : Post.mockIdealWorld

            if let category = self.selectedCategory {
                self.searchResults = allPosts.filter { $0.category == category }
            } else {
                self.searchResults = allPosts.filter {
                    $0.content.localizedCaseInsensitiveContains(self.searchText)
                }
            }
        }
    }

    func selectCategory(_ category: PostCategory) {
        selectedCategory = category
        search()
    }

    func clearCategory() {
        selectedCategory = nil
        searchResults = []
    }

    func selectPostType(_ type: Post.PostType) {
        selectedPostType = type
        selectedCategory = nil
        searchResults = []
    }
}
