import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showCreatePost = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)

                SearchView()
                    .tag(1)

                // Placeholder for center button
                Color.clear
                    .tag(2)

                ProfileView()
                    .tag(3)

                SettingsView()
                    .tag(4)
            }

            // Custom tab bar
            CustomTabBar(
                selectedTab: $selectedTab,
                showCreatePost: $showCreatePost
            )
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostView()
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showCreatePost: Bool

    var body: some View {
        HStack {
            // Home
            TabBarButton(
                icon: "house.fill",
                title: "ホーム",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }

            // Search
            TabBarButton(
                icon: "magnifyingglass",
                title: "検索",
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
            }

            // Create Post (center button)
            Button(action: {
                showCreatePost = true
            }) {
                ZStack {
                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: 56, height: 56)
                        .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -20)

            // Profile
            TabBarButton(
                icon: "person.fill",
                title: "マイページ",
                isSelected: selectedTab == 3
            ) {
                selectedTab = 3
            }

            // Settings
            TabBarButton(
                icon: "gearshape.fill",
                title: "設定",
                isSelected: selectedTab == 4
            ) {
                selectedTab = 4
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 20)
        .background(
            Color.white
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 10))
            }
            .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
        .environmentObject(AppState())
}
