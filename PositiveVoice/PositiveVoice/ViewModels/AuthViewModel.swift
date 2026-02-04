import SwiftUI
import AuthenticationServices

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var needsProfileSetup: Bool = false

    init() {
        checkAuthState()
    }

    private func checkAuthState() {
        // Check if user is already authenticated (from Cognito)
        // For now, using UserDefaults as placeholder
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) {
        isLoading = true
        errorMessage = nil

        // TODO: Implement AWS Cognito Apple Sign In
        // For now, create mock user
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            self.needsProfileSetup = true
        }
    }

    func signInWithGoogle() {
        isLoading = true
        errorMessage = nil

        // TODO: Implement AWS Cognito Google Sign In
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            self.needsProfileSetup = true
        }
    }

    func signInWithEmail(email: String, password: String) {
        isLoading = true
        errorMessage = nil

        // TODO: Implement AWS Cognito Email Sign In
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            // Mock successful login
            let user = User(
                id: UUID().uuidString,
                nickname: "ユーザー",
                email: email,
                authProvider: .email,
                bio: nil,
                avatarURL: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            self.completeSignIn(user: user)
        }
    }

    func signUpWithEmail(email: String, password: String) {
        isLoading = true
        errorMessage = nil

        // TODO: Implement AWS Cognito Email Sign Up
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            self.needsProfileSetup = true
        }
    }

    func setupProfile(nickname: String, bio: String?) {
        isLoading = true

        // TODO: Save profile to backend
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let user = User(
                id: UUID().uuidString,
                nickname: nickname,
                email: "user@example.com",
                authProvider: .email,
                bio: bio,
                avatarURL: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            self.completeSignIn(user: user)
            self.needsProfileSetup = false
        }
    }

    private func completeSignIn(user: User) {
        self.currentUser = user
        self.isAuthenticated = true
        self.isLoading = false

        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
    }

    func signOut() {
        // TODO: Implement AWS Cognito Sign Out
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
}
