import Foundation

// AWS Amplifyは後から追加します
// 現在はモックモードで動作します

protocol AuthServiceProtocol {
    func signUp(email: String, password: String) async throws -> String
    func confirmSignUp(email: String, code: String) async throws -> Bool
    func signIn(email: String, password: String) async throws -> Bool
    func signInWithApple() async throws -> Bool
    func signInWithGoogle() async throws -> Bool
    func signOut() async throws
    func getCurrentUser() async throws -> User?
    func isSignedIn() async -> Bool
}

class AuthService: AuthServiceProtocol {
    static let shared = AuthService()

    private init() {}

    // MARK: - Sign Up (Mock)

    func signUp(email: String, password: String) async throws -> String {
        // モック: 常に成功
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
        print("AuthService: Mock sign up for \(email)")
        return email
    }

    // MARK: - Confirm Sign Up (Mock)

    func confirmSignUp(email: String, code: String) async throws -> Bool {
        try await Task.sleep(nanoseconds: 500_000_000)
        print("AuthService: Mock confirm sign up")
        return true
    }

    // MARK: - Sign In (Mock)

    func signIn(email: String, password: String) async throws -> Bool {
        try await Task.sleep(nanoseconds: 500_000_000)
        print("AuthService: Mock sign in for \(email)")
        return true
    }

    // MARK: - Social Sign In (Mock)

    func signInWithApple() async throws -> Bool {
        try await Task.sleep(nanoseconds: 500_000_000)
        print("AuthService: Mock Apple sign in")
        return true
    }

    func signInWithGoogle() async throws -> Bool {
        try await Task.sleep(nanoseconds: 500_000_000)
        print("AuthService: Mock Google sign in")
        return true
    }

    // MARK: - Sign Out (Mock)

    func signOut() async throws {
        print("AuthService: Mock sign out")
    }

    // MARK: - Current User (Mock)

    func getCurrentUser() async throws -> User? {
        return User.mock
    }

    // MARK: - Session Check (Mock)

    func isSignedIn() async -> Bool {
        return false
    }
}
