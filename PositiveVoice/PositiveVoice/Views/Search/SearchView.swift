import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textSecondary)

                    TextField("キーワードで検索", text: $viewModel.searchText)
                        .font(AppFonts.body())
                        .onSubmit {
                            viewModel.search()
                        }

                    if !viewModel.searchText.isEmpty {
                        Button(action: {
                            viewModel.searchText = ""
                            viewModel.searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(12)
                .padding()

                // Post type tabs
                PostTypeTabView(
                    selectedType: $viewModel.selectedPostType,
                    onSelect: { type in
                        viewModel.selectPostType(type)
                    }
                )

                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Selected category indicator
                        if let category = viewModel.selectedCategory {
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: category.icon)
                                    Text(category.displayName)
                                }
                                .font(AppFonts.body(14))
                                .foregroundColor(category.color)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(category.color.opacity(0.1))
                                .cornerRadius(16)

                                Button(action: {
                                    viewModel.clearCategory()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Search results or categories
                        if viewModel.isSearching {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding(.vertical, 40)
                        } else if !viewModel.searchResults.isEmpty {
                            // Search results
                            VStack(spacing: 12) {
                                ForEach(viewModel.searchResults) { post in
                                    NavigationLink(destination: PostDetailView(post: post)) {
                                        PostCardView(post: post)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        } else if viewModel.selectedCategory == nil {
                            // Category grid
                            VStack(alignment: .leading, spacing: 12) {
                                Text("カテゴリから探す")
                                    .font(AppFonts.headline())
                                    .foregroundColor(AppColors.textPrimary)
                                    .padding(.horizontal)

                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    ForEach(viewModel.categories) { category in
                                        CategoryButton(category: category) {
                                            viewModel.selectCategory(category)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        } else {
                            // No results
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color.gray.opacity(0.5))
                                Text("検索結果がありません")
                                    .font(AppFonts.body())
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .background(AppColors.background)
            .navigationTitle("検索")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CategoryButton: View {
    let category: PostCategory
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 16))
                Text(category.displayName)
                    .font(AppFonts.body(14))
            }
            .foregroundColor(category.color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

#Preview {
    SearchView()
}
