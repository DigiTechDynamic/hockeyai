import SwiftUI

// MARK: - STY Check Intro Screen
struct STYCheckIntroScreen: View {
    @Environment(\.theme) var theme
    @ObservedObject var viewModel: OnboardingViewModel
    @ObservedObject var coordinator: OnboardingFlowCoordinator

    @State private var appeared = false

    var body: some View {
        ZStack {
            // Subtle animated background
            BackgroundAnimationView(type: .energyWaves, isActive: true, intensity: 0.3)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                // Headline - Exclusive/gatekeeping vibe
                Text("STY Entry Check")
                    .font(.system(size: 42, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color.white.opacity(0.95)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.white.opacity(0.5), radius: 0, x: 0, y: 0)
                    .shadow(color: Color.white.opacity(0.3), radius: 4, x: 0, y: 0)
                    .shadow(color: theme.primary.opacity(0.4), radius: 10, x: 0, y: 2)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1.0 : 0.9)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appeared)
                    .padding(.bottom, theme.spacing.sm)

                // Exclusivity message
                Text("Not everyone gets in")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.primary)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
                    .padding(.bottom, theme.spacing.xl)

                // Subheadline - gatekeeping vibe
                Text("Upload a selfie to prove you're a stud")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.bottom, theme.spacing.xl)

                // Benefits list - centered
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    benefitRow(icon: "🎯", text: "Only beauties get validated")
                    benefitRow(icon: "🔓", text: "Pass = full app access")
                    benefitRow(icon: "📸", text: "Any selfie works")
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)
                .padding(.bottom, theme.spacing.xl)

                Spacer()

                // CTA - Single button, no skip (arrow icon, not camera)
                AppButton(title: "Get Validated", action: {
                    HapticManager.shared.playImpact(style: .medium)

                    // Track in both funnels:
                    // Funnel 1: Onboarding (step 3)
                    OnboardingAnalytics.trackSTYCheck()

                    // Funnel 2: STY validation flow (step 1)
                    STYValidationAnalytics.trackStarted()

                    coordinator.navigateForward()
                })
                .buttonStyle(.primary)
                .withIcon("arrow.right")
                .buttonSize(.large)
                .padding(.horizontal, theme.spacing.lg)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1.0 : 0.95)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: appeared)
                .padding(.bottom, theme.spacing.lg)

                // Footer spacer
                Text(" ")
                    .font(theme.fonts.body)
                    .foregroundColor(.clear)
                    .frame(height: 44)
            }
        }
        .onAppear {
            appeared = true
            HapticManager.shared.playNotification(type: .success)
        }
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: theme.spacing.sm) {
            Text(icon)
                .font(.system(size: 20))

            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.text)
        }
    }
}

