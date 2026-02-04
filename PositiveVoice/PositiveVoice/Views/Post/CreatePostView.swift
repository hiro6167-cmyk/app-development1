import SwiftUI

struct CreatePostView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = PostViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Post type selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("投稿タイプを選択")
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.textPrimary)

                    HStack(spacing: 12) {
                        ForEach(Post.PostType.allCases, id: \.self) { type in
                            PostTypeButton(
                                type: type,
                                isSelected: viewModel.selectedType == type
                            ) {
                                viewModel.selectedType = type
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Content input
                VStack(alignment: .leading, spacing: 8) {
                    TextEditor(text: $viewModel.content)
                        .frame(minHeight: 200)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .overlay(
                            Group {
                                if viewModel.content.isEmpty {
                                    Text(viewModel.selectedType == .goodThing
                                         ? "今日あったいいことを書いてみよう..."
                                         : "こうなって欲しい世の中を書いてみよう...")
                                        .font(AppFonts.body())
                                        .foregroundColor(Color.gray.opacity(0.5))
                                        .padding(16)
                                }
                            },
                            alignment: .topLeading
                        )

                    // Character count
                    HStack {
                        Spacer()
                        Text("\(viewModel.content.count) / \(viewModel.maxCharacters)文字")
                            .font(AppFonts.caption())
                            .foregroundColor(
                                viewModel.charactersRemaining < 0
                                ? .red
                                : AppColors.textSecondary
                            )
                    }
                }
                .padding(.horizontal)

                // AI category info
                HStack(spacing: 8) {
                    Image(systemName: "cpu")
                        .foregroundColor(AppColors.primaryGreen)
                    Text("カテゴリは自動で分類されます")
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 20)
            .background(AppColors.background)
            .navigationTitle("新規投稿")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(AppColors.textPrimary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("投稿") {
                        viewModel.submitPost()
                    }
                    .font(AppFonts.headline())
                    .foregroundColor(viewModel.isValid ? AppColors.primaryGreen : Color.gray)
                    .disabled(!viewModel.isValid || viewModel.isSubmitting)
                }
            }
            .overlay {
                if viewModel.isSubmitting {
                    LoadingOverlay()
                }
            }
            .onChange(of: viewModel.isSubmitSuccessful) { _, success in
                if success {
                    dismiss()
                }
            }
        }
    }
}

struct PostTypeButton: View {
    let type: Post.PostType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 24))

                Text(type == .goodThing ? "今日の\nいいこと" : "こうなって\n欲しい世の中")
                    .font(AppFonts.caption(11))
                    .multilineTextAlignment(.center)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                }
            }
            .foregroundColor(isSelected ? AppColors.primaryGreen : AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? AppColors.primaryGreen.opacity(0.1) : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppColors.primaryGreen : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

#Preview {
    CreatePostView()
}
