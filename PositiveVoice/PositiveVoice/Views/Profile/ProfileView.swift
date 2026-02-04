import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var myPosts: [Post] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    VStack(spacing: 16) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 80, height: 80)

                            Image(systemName: "person.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Color.gray)
                        }

                        // Name
                        Text(authViewModel.currentUser?.nickname ?? "ユーザー")
                            .font(AppFonts.title(22))
                            .foregroundColor(AppColors.textPrimary)

                        // Bio
                        if let bio = authViewModel.currentUser?.bio, !bio.isEmpty {
                            Text(bio)
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 20)

                    // Stats
                    VStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar.fill")
                            Text("投稿数")
                        }
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.textPrimary)

                        HStack(spacing: 20) {
                            StatBox(
                                title: "今日のいいこと",
                                count: 15,
                                color: .yellow
                            )
                            StatBox(
                                title: "こうなって欲しい世の中",
                                count: 8,
                                color: AppColors.primaryGreen
                            )
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    .padding(.horizontal)

                    // My posts
                    VStack(alignment: .leading, spacing: 16) {
                        Text("自分の投稿")
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal)

                        if myPosts.isEmpty {
                            // Mock posts for preview
                            ForEach(Post.mockGoodThings.prefix(2)) { post in
                                NavigationLink(destination: PostDetailView(post: post)) {
                                    MyPostCard(post: post)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        } else {
                            ForEach(myPosts) { post in
                                NavigationLink(destination: PostDetailView(post: post)) {
                                    MyPostCard(post: post)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 100)
            }
            .background(AppColors.background)
            .navigationTitle("マイページ")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct StatBox: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(AppFonts.caption(11))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Text("\(count)件")
                .font(AppFonts.title(24))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct MyPostCard: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category
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

            // Content
            Text(post.content)
                .font(AppFonts.body(14))
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(2)

            // Date
            HStack {
                Spacer()
                Text(post.timeAgo)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
