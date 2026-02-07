import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var nickname = ""
    @State private var bio = ""

    var isFormValid: Bool {
        !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Avatar placeholder
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 100, height: 100)

                            Image(systemName: "camera.fill")
                                .font(.system(size: 30))
                                .foregroundColor(Color.gray)
                        }

                        Text("アイコンを設定（任意）")
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.top, 20)

                    // Nickname field
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("ニックネーム")
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.textPrimary)
                            Text("*")
                                .foregroundColor(.red)
                        }

                        TextField("あなたのニックネーム", text: $nickname)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    .padding(.horizontal)

                    // Bio field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("自己紹介（任意）")
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.textPrimary)

                        TextEditor(text: $bio)
                            .frame(height: 120)
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Submit button
                    Button(action: {
                        authViewModel.setupProfile(
                            nickname: nickname,
                            bio: bio.isEmpty ? nil : bio
                        )
                    }) {
                        Text("はじめる")
                            .font(AppFonts.headline())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(isFormValid ? AppColors.primary : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(!isFormValid)
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .background(AppColors.background)
            .navigationTitle("プロフィール設定")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled()
        }
    }
}

#Preview {
    ProfileSetupView()
        .environmentObject(AuthViewModel())
}
