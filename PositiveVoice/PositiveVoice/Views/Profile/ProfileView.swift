import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @State private var selectedTab: ProfileViewModel.ProfileTab = .posts

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

                        // v2: Follow stats
                        HStack(spacing: 32) {
                            NavigationLink(destination: FollowListView(userId: "current_user", listType: .followers)) {
                                VStack(spacing: 4) {
                                    Text("\(viewModel.userProfile?.followerCount ?? 0)")
                                        .font(AppFonts.headline())
                                        .foregroundColor(AppColors.textPrimary)
                                    Text("フォロワー")
                                        .font(AppFonts.caption())
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }

                            NavigationLink(destination: FollowListView(userId: "current_user", listType: .following)) {
                                VStack(spacing: 4) {
                                    Text("\(viewModel.userProfile?.followingCount ?? 0)")
                                        .font(AppFonts.headline())
                                        .foregroundColor(AppColors.textPrimary)
                                    Text("フォロー中")
                                        .font(AppFonts.caption())
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
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
                                title: AppStrings.goodThing,
                                count: 15,
                                color: AppColors.secondary
                            )
                            StatBox(
                                title: AppStrings.idealWorld,
                                count: 8,
                                color: AppColors.primary
                            )
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    .padding(.horizontal)

                    // v2: Tab selector
                    Picker("", selection: $selectedTab) {
                        ForEach(ProfileViewModel.ProfileTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Tab content
                    switch selectedTab {
                    case .posts:
                        PostsTabContent(posts: viewModel.myPosts.isEmpty ? Post.mockGoodThings : viewModel.myPosts)
                    case .bookmarks:
                        BookmarksTabContent(posts: viewModel.bookmarkedPosts)
                    }
                }
                .padding(.bottom, 100)
            }
            .background(AppColors.background)
            .navigationTitle("マイページ")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadMyProfile()
            }
            .onChange(of: selectedTab) { _, newTab in
                if newTab == .bookmarks {
                    Task {
                        await viewModel.loadBookmarks()
                    }
                }
            }
        }
    }
}

// v2: 投稿タブ
struct PostsTabContent: View {
    let posts: [Post]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if posts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 40))
                        .foregroundColor(Color.gray.opacity(0.5))
                    Text("まだ投稿がありません")
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(posts) { post in
                    NavigationLink(destination: PostDetailView(post: post)) {
                        MyPostCard(post: post)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal)
    }
}

// v2: ブックマークタブ
struct BookmarksTabContent: View {
    let posts: [Post]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if posts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 40))
                        .foregroundColor(Color.gray.opacity(0.5))
                    Text("ブックマークした投稿がありません")
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(posts) { post in
                    NavigationLink(destination: PostDetailView(post: post)) {
                        MyPostCard(post: post)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal)
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
