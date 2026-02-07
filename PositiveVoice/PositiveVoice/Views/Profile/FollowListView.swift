import SwiftUI

/// フォロー/フォロワー一覧画面（v2）
struct FollowListView: View {
    @StateObject private var viewModel: FollowListViewModel

    init(userId: String, listType: FollowListViewModel.ListType) {
        _viewModel = StateObject(wrappedValue: FollowListViewModel(userId: userId, listType: listType))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if viewModel.users.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.2")
                        .font(.system(size: 48))
                        .foregroundColor(Color.gray.opacity(0.5))

                    Text(viewModel.title == "フォロワー" ? "フォロワーはいません" : "フォロー中のユーザーはいません")
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.users) { user in
                    NavigationLink(destination: UserProfileView(userId: user.id)) {
                        UserListRow(
                            user: user,
                            onFollowTap: {
                                Task {
                                    await viewModel.toggleFollow(for: user)
                                }
                            }
                        )
                    }
                    .listRowBackground(Color.white)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .listStyle(.plain)
            }
        }
        .background(AppColors.background)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadUsers()
        }
    }
}

struct UserListRow: View {
    let user: UserProfile
    let onFollowTap: () -> Void

    private let followService = FollowService.shared

    var isFollowing: Bool {
        followService.isFollowing(user.id)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: "person.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color.gray)
            }

            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.nickname)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textPrimary)

                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Follow button (don't show for self)
            if user.id != "current_user" {
                Button(action: onFollowTap) {
                    Text(isFollowing ? "フォロー中" : "フォロー")
                        .font(AppFonts.caption(12))
                        .foregroundColor(isFollowing ? AppColors.textSecondary : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(isFollowing ? Color.gray.opacity(0.2) : AppColors.primary)
                        .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        FollowListView(userId: "user1", listType: .followers)
    }
}
