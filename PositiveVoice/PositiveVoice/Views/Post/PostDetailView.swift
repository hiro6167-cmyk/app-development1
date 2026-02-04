import SwiftUI

struct PostDetailView: View {
    @StateObject private var viewModel: PostDetailViewModel

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
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 48, height: 48)

                            Image(systemName: "person.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color.gray)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.post.user?.nickname ?? "Unknown")
                                .font(AppFonts.headline())
                                .foregroundColor(AppColors.textPrimary)

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

                // Similar posts section
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .foregroundColor(AppColors.primaryGreen)
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
        }
        .background(AppColors.background)
        .navigationTitle("投稿詳細")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PostDetailView(post: Post.mockGoodThings[0])
    }
}
