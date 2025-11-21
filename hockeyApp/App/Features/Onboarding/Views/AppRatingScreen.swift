import SwiftUI
import StoreKit

// MARK: - App Rating Screen
struct AppRatingScreen: View {
    @Environment(\.theme) var theme
    @Environment(\.requestReview) var requestReview
    @ObservedObject var viewModel: OnboardingViewModel
    @ObservedObject var coordinator: OnboardingFlowCoordinator

    @State private var animateIn = false
    @State private var selectedStars = 0
    @State private var hasRequestedReview = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: theme.spacing.xl) {
                // STY Athletic Co. logo with glow (matching home screen)
                // Hockey AI Logo
                VStack(spacing: 6) {
                    Text("Hockey AI")
                        .font(.system(size: 40, weight: .black))
                        .italic()
                        .foregroundColor(.white)
                        .shadow(color: Color.white.opacity(0.4), radius: 8, x: 0, y: 0)
                        .shadow(color: theme.primary.opacity(0.5), radius: 16, x: 0, y: 4)
                        .glitchEffect(isActive: true, intensity: 2.0)
                    
                    Text("ELEVATE YOUR GAME")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(5)
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: theme.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .padding(.bottom, theme.spacing.xl)
                .scaleEffect(animateIn ? 1.0 : 0.86)
                .opacity(animateIn ? 1.0 : 0.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: animateIn)
                .padding(.bottom, theme.spacing.lg)

                // Title and message - simplified
                VStack(spacing: theme.spacing.md) {
                    Text("Help Us Grow")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Quick rating = big help for the community")
                        .font(theme.fonts.body)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                }
                .padding(.horizontal, theme.spacing.xl)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.2), value: animateIn)

                // Star rating display
                HStack(spacing: theme.spacing.sm) {
                    ForEach(1...5, id: \.self) { index in
                        Button(action: {
                            // Use haptic-only feedback for star rating interactions
                            HapticManager.shared.playSelection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                selectedStars = index
                            }
                        }) {
                            Image(systemName: index <= selectedStars ? "star.fill" : "star")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(index <= selectedStars ? theme.primary : theme.divider)
                                .scaleEffect(index <= selectedStars ? 1.1 : 1.0)
                                .shadow(
                                    color: index <= selectedStars ? theme.primary.opacity(0.6) : .clear,
                                    radius: 8,
                                    x: 0,
                                    y: 0
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, theme.spacing.md)
                .opacity(animateIn ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.5), value: animateIn)
            }

            Spacer()

            // Fixed footer area - always same height
            VStack(spacing: theme.spacing.sm) {
                // Submit/Continue button
                AppButton(
                    title: hasRequestedReview ? "Continue" : "Submit",
                    action: {
                        HapticManager.shared.playImpact(style: .light)

                        if hasRequestedReview {
                            // Already showed prompt - just continue
                            coordinator.skipNextPage()
                        } else if selectedStars == 5 {
                            // 5 stars: Show iOS App Store prompt, change button to "Continue"
                            requestReview()
                            hasRequestedReview = true
                        } else {
                            // 1-4 stars or no rating: Skip Thank You and go straight to Notifications
                            coordinator.skipNextPage()
                        }
                    }
                )
                .buttonStyle(.primary)
                .withIcon(hasRequestedReview ? "arrow.right" : "star.fill")
                .buttonSize(.large)
                .padding(.horizontal, theme.spacing.lg)

                // Maybe later button (only show before submitting)
                if !hasRequestedReview {
                    Button(action: {
                        coordinator.skipNextPage()
                    }) {
                        Text("Maybe Later")
                            .font(theme.fonts.body)
                            .foregroundColor(theme.textSecondary)
                            .frame(height: 44)
                    }
                }
            }
            .padding(.bottom, theme.spacing.lg)
            .opacity(animateIn ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.7), value: animateIn)
        }
        .onAppear {
            // ✨ Auto-skip if user already triggered the inline prompt during STY Check
            if UserDefaults.standard.bool(forKey: "hasRequestedInlineReview") ||
               UserDefaults.standard.bool(forKey: "hasRatedDuringOnboarding") { // legacy key fallback
                print("✅ [AppRatingScreen] Inline rating request detected - auto-skipping")
                coordinator.skipNextPage()
                return
            }

            withAnimation { animateIn = true }
        }
        .trackScreen("onboarding_rating")
    }
}
