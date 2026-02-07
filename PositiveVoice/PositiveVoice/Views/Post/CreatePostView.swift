import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = PostViewModel()
    @State private var selectedItems: [PhotosPickerItem] = []

    var body: some View {
        NavigationStack {
            ScrollView {
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
                            .frame(minHeight: 150)
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

                    // v2: Image picker section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("画像を追加（任意）")
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.textPrimary)

                            Spacer()

                            Text("\(viewModel.selectedImages.count)/\(viewModel.maxImages)")
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.textSecondary)
                        }

                        // Selected images preview
                        if !viewModel.selectedImages.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.selectedImages.indices, id: \.self) { index in
                                        ImagePreviewCell(
                                            image: viewModel.selectedImages[index],
                                            onRemove: {
                                                viewModel.removeImage(at: index)
                                            }
                                        )
                                    }
                                }
                            }
                        }

                        // Photo picker button
                        if viewModel.canAddMoreImages {
                            PhotosPicker(
                                selection: $selectedItems,
                                maxSelectionCount: viewModel.maxImages - viewModel.selectedImages.count,
                                matching: .images
                            ) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle.angled")
                                    Text("写真を選択")
                                }
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.primary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.primary.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .onChange(of: selectedItems) { _, newItems in
                                Task {
                                    for item in newItems {
                                        if let data = try? await item.loadTransferable(type: Data.self),
                                           let image = UIImage(data: data) {
                                            viewModel.addImages([image])
                                        }
                                    }
                                    selectedItems = []
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // AI category info
                    HStack(spacing: 8) {
                        Image(systemName: "cpu")
                            .foregroundColor(AppColors.primary)
                        Text("カテゴリは自動で分類されます")
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 100)
                }
                .padding(.top, 20)
            }
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
                    .foregroundColor(viewModel.isValid ? AppColors.primary : Color.gray)
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
            .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? AppColors.primary.opacity(0.1) : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppColors.primary : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

// v2: 画像プレビューセル
struct ImagePreviewCell: View {
    let image: UIImage
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.6)))
            }
            .offset(x: 6, y: -6)
        }
    }
}

#Preview {
    CreatePostView()
}
