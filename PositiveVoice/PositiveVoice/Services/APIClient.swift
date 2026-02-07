import Foundation

// MARK: - API Client

actor APIClient {
    static let shared = APIClient()

    private let baseURL: String
    private let session: URLSession

    private init() {
        self.baseURL = AWSConfig.apiEndpoint

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public Methods

    func get<T: Decodable>(_ path: String, queryItems: [URLQueryItem]? = nil) async throws -> T {
        let request = try await buildRequest(path: path, method: "GET", queryItems: queryItems)
        return try await execute(request)
    }

    func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        var request = try await buildRequest(path: path, method: "POST")
        request.httpBody = try JSONEncoder().encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return try await execute(request)
    }

    func post<T: Decodable>(_ path: String) async throws -> T {
        let request = try await buildRequest(path: path, method: "POST")
        return try await execute(request)
    }

    func delete(_ path: String) async throws {
        let request = try await buildRequest(path: path, method: "DELETE")
        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Private Methods

    private func buildRequest(path: String, method: String, queryItems: [URLQueryItem]? = nil) async throws -> URLRequest {
        var components = URLComponents(string: baseURL + path)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        // Add authorization header if token exists
        if let token = await TokenManager.shared.getIdToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            // Handle 401 - Token refresh
            if httpResponse.statusCode == 401 {
                // Try to refresh token
                let refreshed = await TokenManager.shared.refreshTokenIfNeeded()
                if refreshed {
                    // Retry with new token
                    var newRequest = request
                    if let token = await TokenManager.shared.getIdToken() {
                        newRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    }
                    let (retryData, retryResponse) = try await session.data(for: newRequest)

                    guard let retryHttpResponse = retryResponse as? HTTPURLResponse,
                          (200...299).contains(retryHttpResponse.statusCode) else {
                        throw APIError.unauthorized
                    }

                    return try JSONDecoder().decode(T.self, from: retryData)
                } else {
                    throw APIError.unauthorized
                }
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.httpError(statusCode: httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)

        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            print("Decoding error: \(error)")
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }
}

// MARK: - API Error

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case httpError(statusCode: Int)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .invalidResponse:
            return "サーバーからの応答が不正です"
        case .unauthorized:
            return "認証が必要です。再ログインしてください"
        case .httpError(let statusCode):
            return "サーバーエラー: \(statusCode)"
        case .decodingError:
            return "データの解析に失敗しました"
        case .networkError:
            return "ネットワークエラーが発生しました"
        }
    }
}

// MARK: - Token Manager

actor TokenManager {
    static let shared = TokenManager()

    private let keychain = KeychainService.shared
    private var cachedIdToken: String?
    private var cachedRefreshToken: String?
    private var isRefreshing = false

    private init() {}

    func getIdToken() -> String? {
        if let cached = cachedIdToken {
            return cached
        }
        cachedIdToken = keychain.get(key: "id_token")
        return cachedIdToken
    }

    func setTokens(idToken: String, refreshToken: String) {
        cachedIdToken = idToken
        cachedRefreshToken = refreshToken
        keychain.set(value: idToken, key: "id_token")
        keychain.set(value: refreshToken, key: "refresh_token")
    }

    func clearTokens() {
        cachedIdToken = nil
        cachedRefreshToken = nil
        keychain.delete(key: "id_token")
        keychain.delete(key: "refresh_token")
    }

    func refreshTokenIfNeeded() async -> Bool {
        // Prevent concurrent refresh attempts
        guard !isRefreshing else { return false }
        isRefreshing = true
        defer { isRefreshing = false }

        guard let refreshToken = cachedRefreshToken ?? keychain.get(key: "refresh_token") else {
            return false
        }

        do {
            let newTokens = try await CognitoService.shared.refreshSession(refreshToken: refreshToken)
            setTokens(idToken: newTokens.idToken, refreshToken: newTokens.refreshToken ?? refreshToken)
            return true
        } catch {
            print("Token refresh failed: \(error)")
            clearTokens()
            return false
        }
    }
}

// MARK: - Keychain Service

class KeychainService {
    static let shared = KeychainService()

    private let serviceName = "com.positivevoice.app"

    private init() {}

    func set(value: String, key: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }

    func clearAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]

        SecItemDelete(query as CFDictionary)
    }
}
