import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "sun.max.fill",
            iconColor: .yellow,
            title: "今日あった「いいこと」\nを共有しよう",
            description: "日常の小さな幸せを\nみんなとシェア"
        ),
        OnboardingPage(
            icon: "globe.asia.australia.fill",
            iconColor: AppColors.primary,
            title: "「こうなって欲しい世の中」\nを語ろう",
            description: "あなたの理想を\n声にしよう"
        ),
        OnboardingPage(
            icon: "person.3.fill",
            iconColor: AppColors.secondary,
            title: "同じ想いの人と\nつながる",
            description: "似た考えの投稿が\n自動で見つかる"
        )
    ]

    var body: some View {
        VStack {
            // Skip button
            HStack {
                Spacer()
                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        appState.completeOnboarding()
                    }
                    .foregroundColor(AppColors.textSecondary)
                    .padding()
                }
            }

            // Page content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Page indicator
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? AppColors.primary : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.bottom, 20)

            // Button
            Button(action: {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    appState.completeOnboarding()
                }
            }) {
                Text(currentPage < pages.count - 1 ? "次へ" : "はじめる")
                    .font(AppFonts.headline())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.primary)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .background(AppColors.background)
    }
}

struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.1))
                    .frame(width: 200, height: 200)

                Image(systemName: page.icon)
                    .font(.system(size: 80))
                    .foregroundColor(page.iconColor)
            }

            // Title
            Text(page.title)
                .font(AppFonts.title(24))
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            // Description
            Text(page.description)
                .font(AppFonts.body())
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
