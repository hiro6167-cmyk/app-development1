import SwiftUI

enum AppColors {
    static let primary = Color("Primary", bundle: nil)
    static let secondary = Color("Secondary", bundle: nil)

    // Fallback colors
    static let primaryGreen = Color(red: 76/255, green: 175/255, blue: 80/255)
    static let secondaryOrange = Color(red: 255/255, green: 152/255, blue: 0/255)
    static let background = Color(red: 250/255, green: 250/255, blue: 250/255)
    static let surface = Color.white
    static let textPrimary = Color(red: 33/255, green: 33/255, blue: 33/255)
    static let textSecondary = Color(red: 117/255, green: 117/255, blue: 117/255)
}

enum AppFonts {
    static func title(_ size: CGFloat = 24) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }

    static func headline(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
}

enum AppStrings {
    static let appName = "PositiveVoice"
    static let goodThing = "今日のいいこと"
    static let idealWorld = "こうなって欲しい世の中"
    static let post = "投稿する"
    static let search = "検索"
    static let profile = "プロフィール"
    static let settings = "設定"
}
