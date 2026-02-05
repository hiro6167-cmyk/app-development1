import Foundation

// AWS Amplifyは後から追加します
// 現在はモックモードで動作します

class AmplifyService {
    static let shared = AmplifyService()

    private init() {}

    func configure() async throws {
        // TODO: AWS Amplify設定（後で実装）
        print("AmplifyService: Mock mode - AWS not configured yet")
    }
}
