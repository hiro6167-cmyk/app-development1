import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Post type tabs
                PostTypeTabView(
                    selectedType: $viewModel.selectedPostType,
                    onSelect: { type in
                        viewModel.selectPostType(type)
                    }
                )

                // Sort order picker
                HStack {
                    Menu {
                        ForEach(HomeViewModel.SortOrder.allCases, id: \.self) { order in
                            Button(action: {
                                viewModel.setSortOrder(order)
                            }) {
                                HStack {
                                    Text(order.displayName)
                                    if viewModel.sortOrder == order {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(viewModel.sortOrder.displayName)
                                .font(AppFonts.caption(14))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Posts list
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.posts.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "bubble.left.and.bubble.right",
                        title: "投稿がありません",
                        description: "最初の投稿をしてみましょう"
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.posts) { post in
                                NavigationLink(destination: PostDetailView(post: post)) {
                                    PostCardView(post: post)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        viewModel.refreshPosts()
                    }
                }
            }
            .background(AppColors.background)
            .navigationTitle(AppStrings.appName)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct PostTypeTabView: View {
    @Binding var selectedType: Post.PostType
    let onSelect: (Post.PostType) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Post.PostType.allCases, id: \.self) { type in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedType = type
                        onSelect(type)
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(type.displayName)
                            .font(AppFonts.body(14))
                            .foregroundColor(selectedType == type ? AppColors.primary : AppColors.textSecondary)

                        Rectangle()
                            .fill(selectedType == type ? AppColors.primary : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 8)
        .background(Color.white)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(Color.gray.opacity(0.5))

            Text(title)
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)

            Text(description)
                .font(AppFonts.body())
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

#Preview {
    HomeView()
}
