import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showEmailAuth = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()

                // Logo
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(AppColors.primaryGreen.opacity(0.1))
                            .frame(width: 100, height: 100)

                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 40))
                            .foregroundColor(AppColors.primaryGreen)
                    }

                    Text(AppStrings.appName)
                        .font(AppFonts.title(28))
                        .foregroundColor(AppColors.textPrimary)
                }

                Spacer()

                // Auth buttons
                VStack(spacing: 16) {
                    // Sign in with Apple
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                authViewModel.signInWithApple(credential: appleIDCredential)
                            }
                        case .failure(let error):
                            authViewModel.errorMessage = error.localizedDescription
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(12)

                    // Sign in with Google
                    Button(action: {
                        authViewModel.signInWithGoogle()
                    }) {
                        HStack {
                            Image(systemName: "g.circle.fill")
                                .font(.title2)
                            Text("Googleでサインイン")
                                .font(AppFonts.headline())
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red)
                        .cornerRadius(12)
                    }

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        Text("または")
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.textSecondary)
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }

                    // Email sign in
                    Button(action: {
                        showEmailAuth = true
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .font(.title2)
                            Text("メールで登録")
                                .font(AppFonts.headline())
                        }
                        .foregroundColor(AppColors.primaryGreen)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.primaryGreen, lineWidth: 2)
                        )
                    }
                }
                .padding(.horizontal, 30)

                // Already have account
                Button(action: {
                    showEmailAuth = true
                }) {
                    Text("すでにアカウントをお持ちの方は")
                        .foregroundColor(AppColors.textSecondary)
                    + Text("ログイン")
                        .foregroundColor(AppColors.primaryGreen)
                }
                .font(AppFonts.caption(14))
                .padding(.bottom, 40)
            }
            .background(AppColors.background)
            .sheet(isPresented: $showEmailAuth) {
                EmailAuthView()
            }
            .sheet(isPresented: $authViewModel.needsProfileSetup) {
                ProfileSetupView()
            }
            .overlay {
                if authViewModel.isLoading {
                    LoadingOverlay()
                }
            }
        }
    }
}

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
                .padding(30)
                .background(Color.black.opacity(0.7))
                .cornerRadius(16)
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
}
