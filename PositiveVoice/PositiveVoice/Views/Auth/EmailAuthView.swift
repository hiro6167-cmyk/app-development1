import SwiftUI

struct EmailAuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    var isFormValid: Bool {
        if isLogin {
            return !email.isEmpty && !password.isEmpty
        } else {
            return !email.isEmpty && !password.isEmpty && password == confirmPassword && password.count >= 8
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Toggle between login/signup
                Picker("", selection: $isLogin) {
                    Text("ログイン").tag(true)
                    Text("新規登録").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                VStack(spacing: 16) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("メールアドレス")
                            .font(AppFonts.caption(14))
                            .foregroundColor(AppColors.textSecondary)
                        TextField("example@email.com", text: $email)
                            .textFieldStyle(CustomTextFieldStyle())
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }

                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("パスワード")
                            .font(AppFonts.caption(14))
                            .foregroundColor(AppColors.textSecondary)
                        SecureField("8文字以上", text: $password)
                            .textFieldStyle(CustomTextFieldStyle())
                            .textContentType(isLogin ? .password : .newPassword)
                    }

                    // Confirm password (signup only)
                    if !isLogin {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("パスワード（確認）")
                                .font(AppFonts.caption(14))
                                .foregroundColor(AppColors.textSecondary)
                            SecureField("もう一度入力", text: $confirmPassword)
                                .textFieldStyle(CustomTextFieldStyle())
                                .textContentType(.newPassword)
                        }

                        if !confirmPassword.isEmpty && password != confirmPassword {
                            Text("パスワードが一致しません")
                                .font(AppFonts.caption())
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.horizontal)

                // Error message
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(AppFonts.caption())
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                // Submit button
                Button(action: {
                    if isLogin {
                        authViewModel.signInWithEmail(email: email, password: password)
                    } else {
                        authViewModel.signUpWithEmail(email: email, password: password)
                    }
                }) {
                    Text(isLogin ? "ログイン" : "登録する")
                        .font(AppFonts.headline())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isFormValid ? AppColors.primary : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isFormValid)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle(isLogin ? "ログイン" : "新規登録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    dismiss()
                }
            }
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
    }
}

#Preview {
    EmailAuthView()
        .environmentObject(AuthViewModel())
}
