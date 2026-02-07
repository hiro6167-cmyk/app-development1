import Foundation
import CryptoKit

// MARK: - Cognito Service

actor CognitoService {
    static let shared = CognitoService()

    private let region = AWSConfig.region
    private let userPoolId = AWSConfig.userPoolId
    private let clientId = AWSConfig.userPoolClientId
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String, nickname: String) async throws -> SignUpResult {
        let request = CognitoRequest(
            action: "SignUp",
            body: [
                "ClientId": clientId,
                "Username": email,
                "Password": password,
                "UserAttributes": [
                    ["Name": "email", "Value": email],
                    ["Name": "nickname", "Value": nickname]
                ]
            ]
        )

        let response: SignUpResponse = try await execute(request)
        return SignUpResult(
            userConfirmed: response.UserConfirmed,
            userId: response.UserSub
        )
    }

    // MARK: - Confirm Sign Up

    func confirmSignUp(email: String, code: String) async throws {
        let request = CognitoRequest(
            action: "ConfirmSignUp",
            body: [
                "ClientId": clientId,
                "Username": email,
                "ConfirmationCode": code
            ]
        )

        let _: EmptyResponse = try await execute(request)
    }

    // MARK: - Sign In (USER_PASSWORD_AUTH)

    func signIn(email: String, password: String) async throws -> AuthTokens {
        let request = CognitoRequest(
            action: "InitiateAuth",
            body: [
                "AuthFlow": "USER_PASSWORD_AUTH",
                "ClientId": clientId,
                "AuthParameters": [
                    "USERNAME": email,
                    "PASSWORD": password
                ]
            ]
        )

        let response: InitiateAuthResponse = try await execute(request)

        guard let result = response.AuthenticationResult else {
            throw CognitoError.authenticationFailed
        }

        return AuthTokens(
            idToken: result.IdToken,
            accessToken: result.AccessToken,
            refreshToken: result.RefreshToken,
            expiresIn: result.ExpiresIn
        )
    }

    // MARK: - Refresh Session

    func refreshSession(refreshToken: String) async throws -> AuthTokens {
        let request = CognitoRequest(
            action: "InitiateAuth",
            body: [
                "AuthFlow": "REFRESH_TOKEN_AUTH",
                "ClientId": clientId,
                "AuthParameters": [
                    "REFRESH_TOKEN": refreshToken
                ]
            ]
        )

        let response: InitiateAuthResponse = try await execute(request)

        guard let result = response.AuthenticationResult else {
            throw CognitoError.refreshFailed
        }

        return AuthTokens(
            idToken: result.IdToken,
            accessToken: result.AccessToken,
            refreshToken: result.RefreshToken,
            expiresIn: result.ExpiresIn
        )
    }

    // MARK: - Get User

    func getUser(accessToken: String) async throws -> CognitoUser {
        let request = CognitoRequest(
            action: "GetUser",
            body: [
                "AccessToken": accessToken
            ]
        )

        let response: GetUserResponse = try await execute(request)

        var email = ""
        var nickname = ""

        for attr in response.UserAttributes {
            switch attr.Name {
            case "email":
                email = attr.Value
            case "nickname":
                nickname = attr.Value
            default:
                break
            }
        }

        return CognitoUser(
            userId: response.Username,
            email: email,
            nickname: nickname
        )
    }

    // MARK: - Sign Out (Global)

    func globalSignOut(accessToken: String) async throws {
        let request = CognitoRequest(
            action: "GlobalSignOut",
            body: [
                "AccessToken": accessToken
            ]
        )

        let _: EmptyResponse = try await execute(request)
    }

    // MARK: - Forgot Password

    func forgotPassword(email: String) async throws {
        let request = CognitoRequest(
            action: "ForgotPassword",
            body: [
                "ClientId": clientId,
                "Username": email
            ]
        )

        let _: ForgotPasswordResponse = try await execute(request)
    }

    // MARK: - Confirm Forgot Password

    func confirmForgotPassword(email: String, code: String, newPassword: String) async throws {
        let request = CognitoRequest(
            action: "ConfirmForgotPassword",
            body: [
                "ClientId": clientId,
                "Username": email,
                "ConfirmationCode": code,
                "Password": newPassword
            ]
        )

        let _: EmptyResponse = try await execute(request)
    }

    // MARK: - Private Execute

    private func execute<T: Decodable>(_ request: CognitoRequest) async throws -> T {
        let url = URL(string: "https://cognito-idp.\(region).amazonaws.com/")!

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/x-amz-json-1.1", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("AWSCognitoIdentityProviderService.\(request.action)", forHTTPHeaderField: "X-Amz-Target")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: request.body)

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CognitoError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            // Try to parse error
            if let errorResponse = try? JSONDecoder().decode(CognitoErrorResponse.self, from: data) {
                throw CognitoError.apiError(code: errorResponse.__type, message: errorResponse.message)
            }
            throw CognitoError.httpError(statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - Request/Response Models

private struct CognitoRequest {
    let action: String
    let body: [String: Any]
}

private struct SignUpResponse: Decodable {
    let UserConfirmed: Bool
    let UserSub: String
}

private struct InitiateAuthResponse: Decodable {
    let AuthenticationResult: AuthenticationResult?
    let ChallengeName: String?
}

private struct AuthenticationResult: Decodable {
    let IdToken: String
    let AccessToken: String
    let RefreshToken: String?
    let ExpiresIn: Int
}

private struct GetUserResponse: Decodable {
    let Username: String
    let UserAttributes: [UserAttribute]
}

private struct UserAttribute: Decodable {
    let Name: String
    let Value: String
}

private struct ForgotPasswordResponse: Decodable {
    let CodeDeliveryDetails: CodeDeliveryDetails?
}

private struct CodeDeliveryDetails: Decodable {
    let Destination: String?
    let DeliveryMedium: String?
}

private struct EmptyResponse: Decodable {}

private struct CognitoErrorResponse: Decodable {
    let __type: String
    let message: String
}

// MARK: - Public Models

struct SignUpResult {
    let userConfirmed: Bool
    let userId: String
}

struct AuthTokens {
    let idToken: String
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
}

struct CognitoUser {
    let userId: String
    let email: String
    let nickname: String
}

// MARK: - Cognito Error

enum CognitoError: Error, LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case authenticationFailed
    case refreshFailed
    case apiError(code: String, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "サーバーからの応答が不正です"
        case .httpError(let statusCode):
            return "サーバーエラー: \(statusCode)"
        case .authenticationFailed:
            return "認証に失敗しました"
        case .refreshFailed:
            return "セッションの更新に失敗しました"
        case .apiError(let code, let message):
            return mapErrorMessage(code: code, message: message)
        }
    }

    private func mapErrorMessage(code: String, message: String) -> String {
        switch code {
        case "UsernameExistsException":
            return "このメールアドレスは既に登録されています"
        case "InvalidPasswordException":
            return "パスワードが要件を満たしていません"
        case "UserNotFoundException":
            return "ユーザーが見つかりません"
        case "NotAuthorizedException":
            return "メールアドレスまたはパスワードが正しくありません"
        case "CodeMismatchException":
            return "確認コードが正しくありません"
        case "ExpiredCodeException":
            return "確認コードの有効期限が切れています"
        case "UserNotConfirmedException":
            return "メールアドレスの確認が完了していません"
        case "TooManyRequestsException":
            return "リクエストが多すぎます。しばらく待ってから再試行してください"
        default:
            return message
        }
    }
}
