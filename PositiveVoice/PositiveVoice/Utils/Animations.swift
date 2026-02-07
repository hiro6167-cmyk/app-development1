import SwiftUI

// MARK: - Animation Extensions (v2)

extension View {
    /// カード表示時のスライドインアニメーション
    func slideInAnimation(delay: Double = 0) -> some View {
        self
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .opacity
            ))
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay), value: UUID())
    }

    /// ボタンタップ時のスケールアニメーション
    func tapScaleEffect() -> some View {
        self.buttonStyle(TapScaleButtonStyle())
    }

    /// フェードインアニメーション
    func fadeInAnimation(delay: Double = 0) -> some View {
        self.modifier(FadeInModifier(delay: delay))
    }

    /// ハートアニメーション（ブックマーク用）
    func heartBeatAnimation(_ isActive: Bool) -> some View {
        self.modifier(HeartBeatModifier(isActive: isActive))
    }
}

// MARK: - Button Styles

struct TapScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool

    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.headline())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isEnabled ? AppColors.primary : Color.gray)
            .cornerRadius(AppLayout.buttonCornerRadius)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Animation Modifiers

struct FadeInModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

struct HeartBeatModifier: ViewModifier {
    let isActive: Bool
    @State private var scale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        scale = 1.3
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.15)) {
                        scale = 1.0
                    }
                }
            }
    }
}

// MARK: - Shimmer Effect (Loading placeholder)

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.3),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    /// ローディング中のシマーエフェクト
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

// MARK: - Pull to Refresh Custom Indicator

struct CustomRefreshIndicator: View {
    let isRefreshing: Bool

    var body: some View {
        HStack(spacing: 8) {
            if isRefreshing {
                ProgressView()
                    .tint(AppColors.primary)
                Text("更新中...")
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .frame(height: 50)
    }
}
