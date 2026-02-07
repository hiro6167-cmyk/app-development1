import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.5

    var body: some View {
        ZStack {
            // v2: Gradient background
            LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // v2: Enhanced logo animation
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 3)
                        .frame(width: 140, height: 140)
                        .scaleEffect(ringScale)

                    // Inner circle
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 120, height: 120)

                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .scaleEffect(isAnimating ? 1.0 : 0.9)
                }
                .opacity(logoOpacity)

                Text(AppStrings.appName)
                    .font(AppFonts.title(32))
                    .foregroundColor(.white)
                    .opacity(textOpacity)

                // v2: Custom loading dots
                LoadingDotsView()
                    .padding(.top, 40)
                    .opacity(textOpacity)
            }
        }
        .onAppear {
            // Staggered animations
            withAnimation(.easeOut(duration: 0.6)) {
                logoOpacity = 1
                ringScale = 1.0
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                textOpacity = 1
            }

            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// v2: カスタムローディングドット
struct LoadingDotsView: View {
    @State private var dotOpacities: [Double] = [0.3, 0.3, 0.3]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 10, height: 10)
                    .opacity(dotOpacities[index])
            }
        }
        .onAppear {
            animateDots()
        }
    }

    private func animateDots() {
        for index in 0..<3 {
            withAnimation(
                .easeInOut(duration: 0.4)
                .repeatForever(autoreverses: true)
                .delay(Double(index) * 0.15)
            ) {
                dotOpacities[index] = 1.0
            }
        }
    }
}

#Preview {
    SplashView()
}
