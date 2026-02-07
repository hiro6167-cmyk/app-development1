import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isLoading {
                SplashView()
            } else if !appState.hasCompletedOnboarding {
                OnboardingView()
            } else if !authViewModel.isAuthenticated {
                AuthView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut, value: appState.isLoading)
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
        .preferredColorScheme(appState.preferredColorScheme) // v2: Apply theme setting
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(AppState())
}
