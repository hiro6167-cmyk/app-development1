import Foundation

/// コメント一覧・投稿用ViewModel（v2）
@MainActor
class CommentsViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoading: Bool = false
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?
    @Published var newCommentText: String = ""

    private let postId: String
    private let commentService = CommentService.shared

    let maxCharacters = 200

    var isValid: Bool {
        !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        newCommentText.count <= maxCharacters
    }

    var charactersRemaining: Int {
        maxCharacters - newCommentText.count
    }

    init(postId: String) {
        self.postId = postId
    }

    func loadComments() async {
        isLoading = true
        errorMessage = nil

        do {
            comments = try await commentService.fetchComments(postId: postId)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func submitComment() async {
        guard isValid else { return }

        isSubmitting = true
        errorMessage = nil

        do {
            let comment = try await commentService.createComment(
                postId: postId,
                content: newCommentText
            )
            comments.insert(comment, at: 0)
            newCommentText = ""
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }

    func deleteComment(_ comment: Comment) async {
        do {
            try await commentService.deleteComment(id: comment.id)
            comments.removeAll { $0.id == comment.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
