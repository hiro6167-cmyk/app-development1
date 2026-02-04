import SwiftUI

class AppState: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var hasCompletedOnboarding: Bool = false

    private let onboardingKey = "hasCompletedOnboarding"

    init() {
        loadOnboardingState()
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
}
