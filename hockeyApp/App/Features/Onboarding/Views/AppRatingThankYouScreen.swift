import SwiftUI
import StoreKit

// MARK: - Thank You Screen (after Rating)
struct AppRatingThankYouScreen: View {
    @Environment(\.theme) var theme
    @Environment(\.requestReview) var requestReview
    @ObservedObject var viewModel: OnboardingViewModel
    @ObservedObject var coordinator: OnboardingFlowCoordinator

    @State private var animateIn = false
    @State private var hasRequestedReview = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: theme.spacing.xl) {
                // Checkmark icon with glow
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.green.opacity(0.2),
                                    Color.green.opacity(0.08),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)

                    // Shadow layer
                    Circle()
                        .fill(Color.black.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .blur(radius: 12)
                        .offset(y: 8)

                    // Main circle
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(Color.green.opacity(0.3), lineWidth: 2)
                        )

                    Image(systemName: "checkmark")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundColor(.green)
                        .shadow(color: Color.green.opacity(0.4), radius: 15, x: 0, y: 0)
                }
                .scaleEffect(animateIn ? 1 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateIn)
                .padding(.vertical, theme.spacing.xl)

                // Title and message
                VStack(spacing: theme.spacing.md) {
                    Text("Thank You!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Your feedback helps us improve!")
                        .font(theme.fonts.body)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                }
                .padding(.horizontal, theme.spacing.xl)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.3), value: animateIn)
            }

            Spacer()

            // Fixed footer area - always same height
            VStack(spacing: theme.spacing.sm) {
                AppButton(title: "Continue", action: {
                    HapticManager.shared.playImpact(style: .light)
                    coordinator.navigateForward()
                })
                .buttonStyle(.primary)
                .buttonSize(.large)
                .padding(.horizontal, theme.spacing.lg)

                // Invisible spacer to match height of "Maybe Later" button
                Text("Placeholder")
                    .font(theme.fonts.body)
                    .foregroundColor(.clear)
                    .frame(height: 44)
            }
            .padding(.bottom, theme.spacing.lg)
            .opacity(animateIn ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.5), value: animateIn)
        }
        .onAppear {
            withAnimation {
                animateIn = true
            }
            // Note: This screen is now skipped in the flow - kept for legacy/fallback
        }
    }
}
