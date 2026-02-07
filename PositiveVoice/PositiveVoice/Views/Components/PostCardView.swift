import SwiftUI

struct PostCardView: View {
    let post: Post
    var onBookmarkTap: (() -> Void)?
    var onShareTap: (() -> Void)?
    var onUserTap: ((String) -> Void)?

    @State private var isBookmarked: Bool = false

    init(
        post: Post,
        onBookmarkTap: (() -> Void)? = nil,
        onShareTap: (() -> Void)? = nil,
        onUserTap: ((String) -> Void)? = nil
    ) {
        self.post = post
        self.onBookmarkTap = onBookmarkTap
        self.onShareTap = onShareTap
        self.onUserTap = onUserTap
        self._isBookmarked = State(initialValue: post.isBookmarked)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Avatar - tappable
                Button(action: {
                    onUserTap?(post.userId)
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: "person.fill")
                            .foregroundColor(Color.gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                VStack(alignment: .leading, spacing: 2) {
                    Button(action: {
                        onUserTap?(post.userId)
                    }) {
                        Text(post.user?.nickname ?? "Unknown")
                            .font(AppFonts.body(14))
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Category badge
                    HStack(spacing: 4) {
                        Image(systemName: post.category.icon)
                            .font(.system(size: 10))
                        Text(post.category.displayName)
                            .font(AppFonts.caption(11))
                    }
                    .foregroundColor(post.category.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(post.category.color.opacity(0.1))
                    .cornerRadius(8)
                }

                Spacer()
            }

            // Content
            Text(post.content)
                .font(AppFonts.body())
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(4)
                .multilineTextAlignment(.leading)

            // v2: Image gallery (if images exist)
            if !post.imageUrls.isEmpty {
                PostImageGallery(imageUrls: post.imageUrls)
            }

            // v2: Action bar (bookmark, comment count, share)
            HStack(spacing: 16) {
                // Comment count
                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 14))
                    Text("\(post.commentCount)")
                        .font(AppFonts.caption())
                }
                .foregroundColor(AppColors.textSecondary)

                Spacer()

                // Bookmark button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isBookmarked.toggle()
                    }
                    onBookmarkTap?()
                }) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 18))
                        .foregroundColor(isBookmarked ? AppColors.primary : AppColors.textSecondary)
                }
                .buttonStyle(PlainButtonStyle())

                // Share button
                Button(action: {
                    onShareTap?()
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textSecondary)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Footer
            HStack {
                Spacer()
                Text(post.timeAgo)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .onAppear {
            // Sync with BookmarkService
            isBookmarked = BookmarkService.shared.isBookmarked(post.id) || post.isBookmarked
        }
    }
}

// v2: 画像ギャラリー
struct PostImageGallery: View {
    let imageUrls: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(imageUrls, id: \.self) { url in
                    // モック: プレースホルダー画像
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(Color.gray.opacity(0.5))
                        )
                }
            }
        }
    }
}

struct PostCardCompactView: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 24, height: 24)

                    Image(systemName: "person.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color.gray)
                }

                Text(post.user?.nickname ?? "Unknown")
                    .font(AppFonts.caption(12))
                    .foregroundColor(AppColors.textSecondary)
            }

            Text(post.content)
                .font(AppFonts.body(14))
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    VStack(spacing: 16) {
        PostCardView(post: Post.mockGoodThings[0])
        PostCardCompactView(post: Post.mockGoodThings[1])
    }
    .padding()
    .background(AppColors.background)
}
