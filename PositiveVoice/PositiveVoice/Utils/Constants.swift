import SwiftUI

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - App Colors (v2: Warm Orange Theme)
// 重要: 緑系の色は一切使用禁止
enum AppColors {
    // メインカラー（温かいオレンジ系）
    static let primary = Color(hex: "FF8C42")      // 温かいオレンジ
    static let secondary = Color(hex: "FFD166")    // 明るいイエロー
    static let accent = Color(hex: "F4845F")       // コーラル

    // 背景
    static let background = Color(hex: "FFF8F0")   // クリーム
    static let surface = Color.white

    // テキスト
    static let textPrimary = Color(hex: "5D4037")  // ブラウン
    static let textSecondary = Color(hex: "8D6E63") // ライトブラウン

    // 状態（緑禁止：オレンジ系で統一）
    static let success = Color(hex: "FFB347")      // オレンジ系（緑は使用禁止）
    static let error = Color(hex: "E57373")        // ソフトレッド
    static let warning = Color(hex: "FFD166")      // イエロー

    // グラデーション
    static let warmGradient = LinearGradient(
        colors: [Color(hex: "FF8C42"), Color(hex: "FFD166")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // ダークモード用
    static let darkBackground = Color(hex: "1A1A1A")
    static let darkSurface = Color(hex: "2D2D2D")
    static let darkPrimary = Color(hex: "FFB266")
    static let darkTextPrimary = Color(hex: "F5F5F5")
    static let darkTextSecondary = Color(hex: "BDBDBD")
}

// MARK: - App Fonts
enum AppFonts {
    static func title(_ size: CGFloat = 24) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func headline(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
}

// MARK: - App Strings (v2: Updated names)
enum AppStrings {
    static let appName = "PositiveVoice"

    // 投稿タイプ名称（v2更新）
    static let goodThing = "今日あったいいこと"
    static let idealWorld = "世界にこうなってほしい"

    // UI
    static let post = "投稿する"
    static let search = "検索"
    static let profile = "プロフィール"
    static let settings = "設定"

    // プレースホルダー
    static let goodThingPlaceholder = "今日あった良いことを書いてみよう..."
    static let idealWorldPlaceholder = "あなたの理想の世界を教えて..."
}

// MARK: - App Layout
enum AppLayout {
    static let cornerRadius: CGFloat = 16
    static let cardCornerRadius: CGFloat = 20
    static let buttonCornerRadius: CGFloat = 12
    static let padding: CGFloat = 16
    static let spacing: CGFloat = 12
    static let minTapTarget: CGFloat = 44
}

// MARK: - AWS Config
enum AWSConfig {
    static let region = "ap-northeast-1"
    static let userPoolId = "ap-northeast-1_qVOFlpxJ1"
    static let userPoolClientId = "34eep7rqmndqrvmln95m3sa76f"
    static let identityPoolId = "ap-northeast-1:368eb286-5c76-4fa1-87db-e8a97c38321b"
    static let apiEndpoint = "https://2qti95chy9.execute-api.ap-northeast-1.amazonaws.com/dev"
    static let mediaBucket = "positivevoice-media-dev-523234425923"
}
