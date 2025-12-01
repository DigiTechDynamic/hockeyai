import SwiftUI
import AVKit

// MARK: - Welcome Screen (reworked, no "Greeny" branding)
struct GreenyWelcomeScreen: View {
    @Environment(\.theme) var theme
    @ObservedObject var viewModel: OnboardingViewModel
    @ObservedObject var coordinator: OnboardingFlowCoordinator

    @State private var appeared = false
    @State private var headlineFinished = false

    var body: some View {
        ZStack {
            // Subtle animated background for depth
            BackgroundAnimationView(type: .energyWaves, isActive: true, intensity: 0.35)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                // Hero mark
                VStack(spacing: 6) {
                    Text("SnapHockey")
                        .font(.system(size: 42, weight: .black))
                        .italic()
                        .foregroundColor(.white)
                        .shadow(color: Color.white.opacity(0.4), radius: 8, x: 0, y: 0)
                        .shadow(color: theme.primary.opacity(0.5), radius: 16, x: 0, y: 4)
                        .glitchEffect(isActive: appeared, intensity: 3.0) // Glitch effect

                    Text("CAPTURE YOUR STYLE")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(6) // Wide tracking like "ATHLETIC CO."
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: theme.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .scaleEffect(appeared ? 1.0 : 0.86)
                .opacity(appeared ? 1.0 : 0.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: appeared)
                .padding(.bottom, theme.spacing.xl)

                // Headline with typewriter effect and haptic ticks
                VStack(spacing: 4) {
                    // First line
                    TypewriterText(
                        "Hockey isn't just skill",
                        characterDelay: 0.03,
                        startDelay: 0.1,
                        hapticsEnabled: true,
                        hapticEvery: 4
                    )
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                    // Second line - emphasized with tighter grouping
                    VStack(spacing: 2) {
                        TypewriterText(
                            "It's style",
                            characterDelay: 0.03,
                            startDelay: 0.6,
                            hapticsEnabled: true,
                            hapticEvery: 2
                        )
                        .font(.system(size: 44, weight: .black))
                        // Match the S icon’s neon green gradient + glow from header
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    theme.primary,
                                    theme.primary.opacity(0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        // Triple-shadow glow to mirror header S logo
                        .shadow(color: theme.primary.opacity(0.6), radius: 12)
                        .shadow(color: theme.primary.opacity(0.42), radius: 8)
                        .shadow(color: theme.primary.opacity(0.3), radius: 4)
                        .multilineTextAlignment(.center)
                        .glitchEffect(isActive: headlineFinished, intensity: 2.0)

                        TypewriterText(
                            "Prove both",
                            characterDelay: 0.03,
                            startDelay: 1.0,
                            hapticsEnabled: true,
                            hapticEvery: 2
                        ) { headlineFinished = true }
                        .font(.system(size: 44, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: Color.white.opacity(0.5), radius: 0, x: 0, y: 0)
                        .shadow(color: Color.white.opacity(0.3), radius: 4, x: 0, y: 0)
                        .shadow(color: theme.primary.opacity(0.4), radius: 10, x: 0, y: 2)
                        .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, theme.spacing.lg)

                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<5) { index in
                        Circle()
                            .fill(index == 0 ? theme.primary : Color.white.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)
                .padding(.top, 32)

                Spacer()

                // CTA
                VStack(spacing: theme.spacing.sm) {
                    AppButton(title: "Start Training", action: {
                        HapticManager.shared.playImpact(style: .light)
                        coordinator.navigateForward()
                    })
                    .buttonStyle(.primary)
                    .withIcon("arrow.right")
                    .buttonSize(.large)
                    .padding(.horizontal, theme.spacing.lg)

                    // Maintain footer height consistency
                    Text(" ")
                        .font(theme.fonts.body)
                        .foregroundColor(.clear)
                        .frame(height: 44)
                }
                .padding(.bottom, theme.spacing.lg)
                .opacity(appeared ? (headlineFinished ? 1 : 0.3) : 0)
                .scaleEffect(headlineFinished ? 1.0 : 0.98)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: headlineFinished)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
            }
        }
        .onAppear {
            appeared = true
            // Gentle success vibe on appear to set tone
            HapticManager.shared.playNotification(type: .success)
        }
    }
}
