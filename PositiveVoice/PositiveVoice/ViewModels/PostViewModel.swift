import SwiftUI
import PhotosUI

class PostViewModel: ObservableObject {
    @Published var content: String = ""
    @Published var selectedType: Post.PostType = .goodThing
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?
    @Published var isSubmitSuccessful: Bool = false

    // v2: 画像選択対応
    @Published var selectedImages: [UIImage] = []
    @Published var isProcessingImages: Bool = false

    let maxCharacters = 300
    let maxImages = 4

    var charactersRemaining: Int {
        maxCharacters - content.count
    }

    var isValid: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        content.count <= maxCharacters
    }

    var canAddMoreImages: Bool {
        selectedImages.count < maxImages
    }

    // MARK: - Image Handling

    func addImages(_ images: [UIImage]) {
        let remainingSlots = maxImages - selectedImages.count
        let imagesToAdd = Array(images.prefix(remainingSlots))
        selectedImages.append(contentsOf: imagesToAdd)
    }

    func removeImage(at index: Int) {
        guard index >= 0 && index < selectedImages.count else { return }
        selectedImages.remove(at: index)
    }

    // MARK: - Submit

    func submitPost() {
        guard isValid else { return }

        isSubmitting = true
        errorMessage = nil

        Task { @MainActor in
            do {
                // 画像がある場合は処理・アップロード
                var imageUrls: [String] = []
                if !selectedImages.isEmpty {
                    isProcessingImages = true
                    imageUrls = try await processAndUploadImages()
                    isProcessingImages = false
                }

                // TODO: Submit to AWS API with AI categorization
                try await Task.sleep(nanoseconds: 500_000_000)

                self.isSubmitting = false
                self.isSubmitSuccessful = true
                self.resetForm()
            } catch {
                self.errorMessage = error.localizedDescription
                self.isSubmitting = false
                self.isProcessingImages = false
            }
        }
    }

    private func processAndUploadImages() async throws -> [String] {
        var processedData: [Data] = []

        for image in selectedImages {
            guard let imageData = image.jpegData(compressionQuality: 1.0) else {
                continue
            }
            let processed = try ImageProcessor.processForUpload(imageData)
            processedData.append(processed)
        }

        let urls = try await ImageService.shared.uploadImages(
            processedData,
            postId: UUID().uuidString
        )

        return urls
    }

    func resetForm() {
        content = ""
        selectedType = .goodThing
        selectedImages = []
    }
}

class PostDetailViewModel: ObservableObject {
    @Published var post: Post
    @Published var similarPosts: [Post] = []
    @Published var comments: [Comment] = []
    @Published var isLoadingSimilar: Bool = false
    @Published var isLoadingComments: Bool = false
    @Published var isBookmarked: Bool = false

    private let bookmarkService = BookmarkService.shared
    private let commentService = CommentService.shared

    init(post: Post) {
        self.post = post
        self.isBookmarked = bookmarkService.isBookmarked(post.id)
        loadSimilarPosts()
        loadComments()
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

    func loadComments() {
        isLoadingComments = true

        Task { @MainActor in
            do {
                comments = try await commentService.fetchComments(postId: post.id)
            } catch {
                print("Failed to load comments: \(error)")
            }
            isLoadingComments = false
        }
    }

    func toggleBookmark() {
        Task { @MainActor in
            do {
                try await bookmarkService.toggle(post.id)
                isBookmarked = bookmarkService.isBookmarked(post.id)
            } catch {
                print("Failed to toggle bookmark: \(error)")
            }
        }
    }
}
