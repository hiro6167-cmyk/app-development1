import SwiftUI

class PostViewModel: ObservableObject {
    @Published var content: String = ""
    @Published var selectedType: Post.PostType = .goodThing
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?
    @Published var isSubmitSuccessful: Bool = false

    let maxCharacters = 300

    var charactersRemaining: Int {
        maxCharacters - content.count
    }

    var isValid: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        content.count <= maxCharacters
    }

    func submitPost() {
        guard isValid else { return }

        isSubmitting = true
        errorMessage = nil

        // TODO: Submit to AWS API with AI categorization
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isSubmitting = false
            self.isSubmitSuccessful = true
            self.resetForm()
        }
    }

    func resetForm() {
        content = ""
        selectedType = .goodThing
    }
}

class PostDetailViewModel: ObservableObject {
    @Published var post: Post
    @Published var similarPosts: [Post] = []
    @Published var isLoadingSimilar: Bool = false

    init(post: Post) {
        self.post = post
        loadSimilarPosts()
    }

    func loadSimilarPosts() {
        isLoadingSimilar = true

        // TODO: Fetch similar posts from AWS using AI embeddings
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoadingSimilar = false
            // Mock similar posts
            if self.post.type == .goodThing {
                self.similarPosts = Array(Post.mockGoodThings.prefix(3))
            } else {
                self.similarPosts = Array(Post.mockIdealWorld.prefix(3))
            }
        }
    }
}
