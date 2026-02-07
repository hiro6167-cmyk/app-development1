import SwiftUI

class AppState: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var hasCompletedOnboarding: Bool = false
    @Published var themeSetting: ThemeSetting = .system

    private let onboardingKey = "hasCompletedOnboarding"
    private let themeKey = "app_theme_setting"

    init() {
        loadOnboardingState()
        loadThemeSetting()
        simulateLoading()
    }

    private func loadOnboardingState() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }

    private func simulateLoading() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                self.isLoading = false
            }
        }
    }

    // MARK: - Theme Management (v2)

    private func loadThemeSetting() {
        if let rawValue = UserDefaults.standard.string(forKey: themeKey),
           let setting = ThemeSetting(rawValue: rawValue) {
            themeSetting = setting
        }
    }

    func setTheme(_ setting: ThemeSetting) {
        themeSetting = setting
        UserDefaults.standard.set(setting.rawValue, forKey: themeKey)
    }

    var preferredColorScheme: ColorScheme? {
        themeSetting.colorScheme
    }
}
