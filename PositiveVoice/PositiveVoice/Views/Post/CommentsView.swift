import SwiftUI

/// コメント一覧・投稿画面（v2）
struct CommentsView: View {
    @StateObject private var viewModel: CommentsViewModel
    @FocusState private var isInputFocused: Bool

    init(postId: String) {
        _viewModel = StateObject(wrappedValue: CommentsViewModel(postId: postId))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Comments list
            ScrollView {
                LazyVStack(spacing: 16) {
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.vertical, 40)
                    } else if viewModel.comments.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 48))
                                .foregroundColor(Color.gray.opacity(0.5))

                            Text("まだコメントはありません")
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.textSecondary)

                            Text("最初のコメントを投稿しましょう")
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(.vertical, 60)
                    } else {
                        ForEach(viewModel.comments) { comment in
                            CommentCard(
                                comment: comment,
                                onDelete: {
                                    Task {
                                        await viewModel.deleteComment(comment)
                                    }
                                }
                            )
                        }
                    }
                }
                .padding()
            }

            // Comment input
            CommentInputBar(
                text: $viewModel.newCommentText,
                isSubmitting: viewModel.isSubmitting,
                charactersRemaining: viewModel.charactersRemaining,
                isValid: viewModel.isValid,
                isFocused: $isInputFocused,
                onSubmit: {
                    Task {
                        await viewModel.submitComment()
                    }
                }
            )
        }
        .background(AppColors.background)
        .navigationTitle("コメント")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadComments()
        }
    }
}

struct CommentCard: View {
    let comment: Comment
    let onDelete: () -> Void

    @State private var showDeleteAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: "person.fill")
                        .font(.system(size: 16))
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

                        Spacer()

                        // Delete button (only for own comments)
                        if comment.userId == "current_user" {
                            Button(action: {
                                showDeleteAlert = true
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }

                    Text(comment.content)
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .alert("コメントを削除", isPresented: $showDeleteAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("このコメントを削除しますか？")
        }
    }
}

struct CommentInputBar: View {
    @Binding var text: String
    let isSubmitting: Bool
    let charactersRemaining: Int
    let isValid: Bool
    var isFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(alignment: .bottom, spacing: 12) {
                // Text input
                TextField("コメントを入力...", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                    .focused(isFocused)

                // Submit button
                Button(action: onSubmit) {
                    if isSubmitting {
                        ProgressView()
                            .frame(width: 44, height: 44)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(isValid ? AppColors.primary : Color.gray)
                    }
                }
                .disabled(!isValid || isSubmitting)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.white)
        }
    }
}

#Preview {
    NavigationStack {
        CommentsView(postId: "test_post")
    }
}
