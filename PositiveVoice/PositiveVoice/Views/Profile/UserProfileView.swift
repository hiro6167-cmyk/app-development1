import SwiftUI

/// 他ユーザーのプロフィール画面（v2）
struct UserProfileView: View {
    @StateObject private var viewModel: UserProfileViewModel

    init(userId: String) {
        _viewModel = StateObject(wrappedValue: UserProfileViewModel(userId: userId))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 60)
                } else if let profile = viewModel.userProfile {
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
                        Text(profile.nickname)
                            .font(AppFonts.title(22))
                            .foregroundColor(AppColors.textPrimary)

                        // Bio
                        if let bio = profile.bio, !bio.isEmpty {
                            Text(bio)
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Follow stats
                        HStack(spacing: 32) {
                            NavigationLink(destination: FollowListView(userId: profile.id, listType: .followers)) {
                                VStack(spacing: 4) {
                                    Text("\(profile.followerCount)")
                                        .font(AppFonts.headline())
                                        .foregroundColor(AppColors.textPrimary)
                                    Text("フォロワー")
                                        .font(AppFonts.caption())
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }

                            NavigationLink(destination: FollowListView(userId: profile.id, listType: .following)) {
                                VStack(spacing: 4) {
                                    Text("\(profile.followingCount)")
                                        .font(AppFonts.headline())
                                        .foregroundColor(AppColors.textPrimary)
                                    Text("フォロー中")
                                        .font(AppFonts.caption())
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                        }

                        // Follow button
                        Button(action: {
                            Task {
                                await viewModel.toggleFollow()
                            }
                        }) {
                            HStack {
                                if viewModel.isFollowLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: viewModel.isFollowing ? "person.badge.minus" : "person.badge.plus")
                                    Text(viewModel.isFollowing ? "フォロー中" : "フォローする")
                                }
                            }
                            .font(AppFonts.headline())
                            .foregroundColor(viewModel.isFollowing ? AppColors.textPrimary : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(viewModel.isFollowing ? Color.gray.opacity(0.2) : AppColors.primary)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isFollowLoading)
                        .padding(.horizontal, 40)
                    }
                    .padding(.top, 20)

                    // Post count stats
                    VStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text")
                            Text("投稿")
                        }
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.textPrimary)

                        Text("\(profile.postCount)件")
                            .font(AppFonts.title(28))
                            .foregroundColor(AppColors.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    .padding(.horizontal)

                    // User's posts
                    VStack(alignment: .leading, spacing: 16) {
                        Text("投稿一覧")
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal)

                        if viewModel.posts.isEmpty {
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
                            ForEach(viewModel.posts) { post in
                                NavigationLink(destination: PostDetailView(post: post)) {
                                    PostCardCompactView(post: post)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 100)
        }
        .background(AppColors.background)
        .navigationTitle("プロフィール")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadProfile()
        }
    }
}

#Preview {
    NavigationStack {
        UserProfileView(userId: "user2")
    }
}
