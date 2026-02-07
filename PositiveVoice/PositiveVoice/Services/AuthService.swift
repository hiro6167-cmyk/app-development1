import Foundation

// MARK: - Auth Service Protocol

protocol AuthServiceProtocol {
    func signUp(email: String, password: String, nickname: String) async throws -> String
    func confirmSignUp(email: String, code: String) async throws -> Bool
    func signIn(email: String, password: String) async throws -> Bool
    func signOut() async throws
    func getCurrentUser() async throws -> User?
    func isSignedIn() async -> Bool
    func resendConfirmationCode(email: String) async throws
    func forgotPassword(email: String) async throws
    func confirmForgotPassword(email: String, code: String, newPassword: String) async throws
}

// MARK: - Auth Service Implementation

class AuthService: AuthServiceProtocol {
    static let shared = AuthService()

    private var currentUserCache: User?
    private var accessToken: String?

    private init() {}

    // MARK: - Sign Up

    func signUp(email: String, password: String, nickname: String = "") async throws -> String {
        let result = try await CognitoService.shared.signUp(
            email: email,
            password: password,
            nickname: nickname.isEmpty ? email.components(separatedBy: "@").first ?? "User" : nickname
        )
        print("AuthService: Sign up successful, userId: \(result.userId)")
        return result.userId
    }

    // MARK: - Confirm Sign Up

    func confirmSignUp(email: String, code: String) async throws -> Bool {
        try await CognitoService.shared.confirmSignUp(email: email, code: code)
        print("AuthService: Confirmation successful")
        return true
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws -> Bool {
        let tokens = try await CognitoService.shared.signIn(email: email, password: password)

        // Store tokens
        await TokenManager.shared.setTokens(
            idToken: tokens.idToken,
            refreshToken: tokens.refreshToken ?? ""
        )
        self.accessToken = tokens.accessToken

        // Fetch user info
        let cognitoUser = try await CognitoService.shared.getUser(accessToken: tokens.accessToken)

        // Create and cache user
        currentUserCache = User(
            id: cognitoUser.userId,
            nickname: cognitoUser.nickname,
            email: cognitoUser.email,
            authProvider: .email,
            bio: nil,
            avatarURL: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        print("AuthService: Sign in successful for \(email)")
        return true
    }

    // MARK: - Sign Out

    func signOut() async throws {
        // Try global sign out if we have access token
        if let accessToken = accessToken {
            do {
                try await CognitoService.shared.globalSignOut(accessToken: accessToken)
            } catch {
                // Continue with local sign out even if global fails
                print("AuthService: Global sign out failed, proceeding with local sign out")
            }
        }

        // Clear local state
        await TokenManager.shared.clearTokens()
        KeychainService.shared.clearAll()
        currentUserCache = nil
        accessToken = nil

        print("AuthService: Sign out completed")
    }

    // MARK: - Get Current User

    func getCurrentUser() async throws -> User? {
        // Return cached user if available
        if let cached = currentUserCache {
            return cached
        }

        // Try to get user from stored tokens
        guard let token = await TokenManager.shared.getIdToken() else {
            return nil
        }

        // We need access token to get user info
        // If we only have ID token, we can decode it to get basic info
        if let userInfo = decodeJWTPayload(token) {
            let userId = userInfo["sub"] as? String ?? ""
            let email = userInfo["email"] as? String ?? ""
            let nickname = userInfo["nickname"] as? String ?? userInfo["cognito:username"] as? String ?? ""

            currentUserCache = User(
                id: userId,
                nickname: nickname,
                email: email,
                authProvider: .email,
                bio: nil,
                avatarURL: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            return currentUserCache
        }

        return nil
    }

    // MARK: - Is Signed In

    func isSignedIn() async -> Bool {
        let token = await TokenManager.shared.getIdToken()
        return token != nil
    }

    // MARK: - Resend Confirmation Code

    func resendConfirmationCode(email: String) async throws {
        // Cognito will send a new code when we call signUp again with same email
        // Or we can use ResendConfirmationCode API
        // For now, advise user to try signing up again
        throw AuthError.notImplemented
    }

    // MARK: - Forgot Password

    func forgotPassword(email: String) async throws {
        try await CognitoService.shared.forgotPassword(email: email)
        print("AuthService: Password reset code sent to \(email)")
    }

    // MARK: - Confirm Forgot Password

    func confirmForgotPassword(email: String, code: String, newPassword: String) async throws {
        try await CognitoService.shared.confirmForgotPassword(
            email: email,
            code: code,
            newPassword: newPassword
        )
        print("AuthService: Password reset successful")
    }

    // MARK: - JWT Decode Helper

    private func decodeJWTPayload(_ jwt: String) -> [String: Any]? {
        let parts = jwt.components(separatedBy: ".")
        guard parts.count == 3 else { return nil }

        var payload = parts[1]
        // Add padding if needed
        while payload.count % 4 != 0 {
            payload += "="
        }

        guard let data = Data(base64Encoded: payload.replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        return json
    }
}

// MARK: - Auth Error

enum AuthError: Error, LocalizedError {
    case notImplemented
    case invalidCredentials
    case userNotFound
    case emailNotConfirmed

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "この機能は現在利用できません"
        case .invalidCredentials:
            return "メールアドレスまたはパスワードが正しくありません"
        case .userNotFound:
            return "ユーザーが見つかりません"
        case .emailNotConfirmed:
            return "メールアドレスの確認が完了していません"
        }
    }
}
