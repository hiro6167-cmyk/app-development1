import SwiftUI

struct PostDetailView: View {
    @StateObject private var viewModel: PostDetailViewModel
    @State private var showShareSheet = false

    init(post: Post) {
        _viewModel = StateObject(wrappedValue: PostDetailViewModel(post: post))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Main post
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        // Avatar
                        NavigationLink(destination: UserProfileView(userId: viewModel.post.userId)) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 48, height: 48)

                                Image(systemName: "person.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color.gray)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            NavigationLink(destination: UserProfileView(userId: viewModel.post.userId)) {
                                Text(viewModel.post.user?.nickname ?? "Unknown")
                                    .font(AppFonts.headline())
                                    .foregroundColor(AppColors.textPrimary)
                            }

                            // Category badge
                            HStack(spacing: 4) {
                                Image(systemName: viewModel.post.category.icon)
                                    .font(.system(size: 12))
                                Text(viewModel.post.category.displayName)
                                    .font(AppFonts.caption(12))
                            }
                            .foregroundColor(viewModel.post.category.color)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(viewModel.post.category.color.opacity(0.1))
                            .cornerRadius(8)
                        }

                        Spacer()
                    }

                    // Content
                    Text(viewModel.post.content)
                        .font(AppFonts.body(17))
                        .foregroundColor(AppColors.textPrimary)
                        .lineSpacing(6)

                    // v2: Image gallery
                    if !viewModel.post.imageUrls.isEmpty {
                        PostImageGallery(imageUrls: viewModel.post.imageUrls)
                    }

                    // v2: Action bar
                    HStack(spacing: 20) {
                        // Comment count
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.right")
                                .font(.system(size: 16))
                            Text("\(viewModel.comments.count)")
                                .font(AppFonts.body())
                        }
                        .foregroundColor(AppColors.textSecondary)

                        Spacer()

                        // Bookmark button
                        Button(action: {
                            viewModel.toggleBookmark()
                        }) {
                            Image(systemName: viewModel.isBookmarked ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 20))
                                .foregroundColor(viewModel.isBookmarked ? AppColors.primary : AppColors.textSecondary)
                        }

                        // Share button
                        Button(action: {
                            showShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .padding(.top, 8)

                    // Date
                    HStack {
                        Spacer()
                        Text(viewModel.post.createdAt, style: .date)
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)

                // v2: Comments section
                CommentsSection(
                    comments: viewModel.comments,
                    isLoading: viewModel.isLoadingComments,
                    postId: viewModel.post.id
                )

                // Similar posts section
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(AppColors.primary)
                        Text("似ている投稿")
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.textPrimary)
                    }

                    if viewModel.isLoadingSimilar {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.vertical, 20)
                    } else if viewModel.similarPosts.isEmpty {
                        Text("似ている投稿が見つかりませんでした")
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.vertical, 20)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(viewModel.similarPosts) { post in
                                NavigationLink(destination: PostDetailView(post: post)) {
                                    PostCardCompactView(post: post)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
        .background(AppColors.background)
        .navigationTitle("投稿詳細")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [viewModel.post.content])
        }
    }
}

// v2: コメントセクション
struct CommentsSection: View {
    let comments: [Comment]
    let isLoading: Bool
    let postId: String

    @State private var showAllComments = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .foregroundColor(AppColors.primary)
                Text("コメント")
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                if comments.count > 3 {
                    NavigationLink(destination: CommentsView(postId: postId)) {
                        Text("すべて見る")
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.primary)
                    }
                }
            }

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 20)
            } else if comments.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 32))
                        .foregroundColor(Color.gray.opacity(0.5))
                    Text("まだコメントはありません")
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(comments.prefix(3)) { comment in
                        CommentRow(comment: comment)
                    }
                }
            }

            // Comment input link
            NavigationLink(destination: CommentsView(postId: postId)) {
                HStack {
                    Image(systemName: "plus.bubble")
                    Text("コメントを追加")
                }
                .font(AppFonts.body())
                .foregroundColor(AppColors.primary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.primary.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// v2: コメント行
struct CommentRow: View {
    let comment: Comment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 32, height: 32)

                Image(systemName: "person.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color.gray)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.user?.nickname ?? "Unknown")
                        .font(AppFonts.body(14))
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)

                    Text(comment.timeAgo)
                        .font(AppFonts.caption(11))
                        .foregroundColor(AppColors.textSecondary)
                }

                Text(comment.content)
                    .font(AppFonts.body(14))
                    .foregroundColor(AppColors.textPrimary)
            }

            Spacer()
        }
    }
}

// v2: シェアシート
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        PostDetailView(post: Post.mockGoodThings[0])
    }
}
