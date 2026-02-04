import Foundation
import Amplify
import AWSCognitoAuthPlugin

protocol AuthServiceProtocol {
    func signUp(email: String, password: String) async throws -> String
    func confirmSignUp(email: String, code: String) async throws -> Bool
    func signIn(email: String, password: String) async throws -> Bool
    func signInWithApple() async throws -> Bool
    func signInWithGoogle() async throws -> Bool
    func signOut() async throws
    func getCurrentUser() async throws -> AuthUser?
    func fetchUserAttributes() async throws -> [AuthUserAttribute]
}

class AuthService: AuthServiceProtocol {
    static let shared = AuthService()

    private init() {}

    // MARK: - Sign Up

    func signUp(email: String, password: String) async throws -> String {
        let userAttributes = [AuthUserAttribute(.email, value: email)]
        let options = AuthSignUpRequest.Options(userAttributes: userAttributes)

        let result = try await Amplify.Auth.signUp(
            username: email,
            password: password,
            options: options
        )

        switch result.nextStep {
        case .confirmUser(let deliveryDetails, _, _):
            print("Confirmation code sent to: \(deliveryDetails?.destination ?? "unknown")")
            return email
        case .done:
            print("Sign up complete")
            return email
        }
    }

    // MARK: - Confirm Sign Up

    func confirmSignUp(email: String, code: String) async throws -> Bool {
        let result = try await Amplify.Auth.confirmSignUp(
            for: email,
            confirmationCode: code
        )

        return result.isSignUpComplete
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws -> Bool {
        let result = try await Amplify.Auth.signIn(
            username: email,
            password: password
        )

        switch result.nextStep {
        case .done:
            print("Sign in succeeded")
            return true
        case .confirmSignUp:
            print("User needs to confirm sign up")
            return false
        default:
            print("Sign in requires additional steps: \(result.nextStep)")
            return false
        }
    }

    // MARK: - Social Sign In

    func signInWithApple() async throws -> Bool {
        let result = try await Amplify.Auth.signInWithWebUI(
            for: .apple,
            presentationAnchor: nil
        )

        return result.isSignedIn
    }

    func signInWithGoogle() async throws -> Bool {
        let result = try await Amplify.Auth.signInWithWebUI(
            for: .google,
            presentationAnchor: nil
        )

        return result.isSignedIn
    }

    // MARK: - Sign Out

    func signOut() async throws {
        let result = await Amplify.Auth.signOut()

        guard let signOutResult = result as? AWSCognitoSignOutResult else {
            print("Sign out failed")
            return
        }

        switch signOutResult {
        case .complete:
            print("Sign out succeeded")
        case .partial(let revokeTokenError, let globalSignOutError, let hostedUIError):
            print("Sign out partial: \(String(describing: revokeTokenError)), \(String(describing: globalSignOutError)), \(String(describing: hostedUIError))")
        case .failed(let error):
            throw error
        }
    }

    // MARK: - Current User

    func getCurrentUser() async throws -> AuthUser? {
        do {
            let user = try await Amplify.Auth.getCurrentUser()
            return user
        } catch {
            return nil
        }
    }

    // MARK: - User Attributes

    func fetchUserAttributes() async throws -> [AuthUserAttribute] {
        return try await Amplify.Auth.fetchUserAttributes()
    }

    // MARK: - Session Check

    func isSignedIn() async -> Bool {
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            return session.isSignedIn
        } catch {
            return false
        }
    }
}
