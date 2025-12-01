import SwiftUI
import StoreKit

// MARK: - App Rating Screen (Greeny Pre-Prompt)
/// Uses psychology-backed pre-prompt to prime users for 5-star rating.
/// Flow: Greeny asks for favor → User commits → iOS prompt appears
/// Based on: Reciprocity, foot-in-the-door technique, specific ask pattern.
struct AppRatingScreen: View {
    @Environment(\.theme) var theme
    @Environment(\.requestReview) var requestReview
    @ObservedObject var viewModel: OnboardingViewModel
    @ObservedObject var coordinator: OnboardingFlowCoordinator

    @State private var animateIn = false
    @State private var hasRequestedReview = false
    @State private var showingPromptPhase = false // After user commits, show brief thank you then prompt

    var body: some View {
        ZStack {
            // Subtle animated background
            BackgroundAnimationView(type: .energyWaves, isActive: true, intensity: 0.25)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                if showingPromptPhase {
                    // Phase 2: Brief "thanks" then iOS prompt triggers
                    thankYouPhase
                } else {
                    // Phase 1: Greeny asks the favor
                    greenyFavorPhase
                }

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    if !showingPromptPhase {
                        // Primary: Commit to rating
                        AppButton(title: "Yeah, I got you", action: {
                            HapticManager.shared.playImpact(style: .medium)
                            OnboardingAnalytics.trackRatingResponse(accepted: true)

                            // Transition to thank you phase, then trigger prompt
                            withAnimation(.easeOut(duration: 0.3)) {
                                showingPromptPhase = true
                            }

                            // Trigger iOS prompt after brief delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                triggerRatingPrompt()
                                // Track STY Validation completed (user accepted rating)
                                STYValidationAnalytics.trackCompleted(ratingAccepted: true)
                            }
                        })
                        .buttonStyle(.primary)
                        .buttonSize(.large)
                        .padding(.horizontal, theme.spacing.lg)

                        // Secondary: Skip
                        Button(action: {
                            HapticManager.shared.playImpact(style: .light)
                            OnboardingAnalytics.trackRatingResponse(accepted: false)
                            // Track STY Validation completed (user skipped rating)
                            STYValidationAnalytics.trackCompleted(ratingAccepted: false)
                            coordinator.navigateForward()
                        }) {
                            Text("Maybe later")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(theme.textSecondary)
                        }
                        .padding(.top, 8)
                    } else {
                        // After prompt, show continue
                        AppButton(title: "Continue", action: {
                            HapticManager.shared.playImpact(style: .light)
                            coordinator.navigateForward()
                        })
                        .buttonStyle(.primary)
                        .withIcon("arrow.right")
                        .buttonSize(.large)
                        .padding(.horizontal, theme.spacing.lg)
                        .opacity(hasRequestedReview ? 1 : 0)
                        .animation(.easeIn(duration: 0.3).delay(0.5), value: hasRequestedReview)
                    }
                }
                .padding(.bottom, theme.spacing.xl)
            }
        }
        .onAppear {
            // Track onboarding funnel step
            OnboardingAnalytics.trackRatingScreen()

            // Track STY Validation funnel step 5 - rating pre-prompt
            STYValidationAnalytics.trackRatingPreprompt()

            // Auto-skip if user already rated
            if UserDefaults.standard.bool(forKey: "hasRequestedInlineReview") ||
               UserDefaults.standard.bool(forKey: "hasRatedDuringOnboarding") {
                print("✅ [AppRatingScreen] Already rated - auto-skipping")
                // Still mark STY validation as completed when auto-skipping
                STYValidationAnalytics.trackCompleted(ratingAccepted: true)
                coordinator.navigateForward()
                return
            }

            withAnimation(.easeOut(duration: 0.5)) {
                animateIn = true
            }
        }
    }

    // MARK: - Phase 1: Greeny Asks the Favor
    private var greenyFavorPhase: some View {
        VStack(spacing: theme.spacing.xl) {
            // Greeny avatar (larger, friendly)
            Image("GreenyProfilePic")
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(theme.primary, lineWidth: 3)
                )
                .shadow(color: theme.primary.opacity(0.4), radius: 12, x: 0, y: 4)
                .scaleEffect(animateIn ? 1 : 0.8)
                .opacity(animateIn ? 1 : 0)

            // "Quick favor?" header
            Text("Quick favor?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 10)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: animateIn)

            // Greeny's message card
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 10) {
                    Image("GreenyProfilePic")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(theme.primary.opacity(0.3), lineWidth: 1.5)
                        )

                    Text("Greeny")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

                Rectangle()
                    .fill(theme.primary.opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                // Message - personal, specific ask
                Text("You're officially in! 🎉\n\nOne quick thing — mind tapping 5 stars on the next screen? Takes 2 seconds and helps other players find us.\n\nThe boys and I would really appreciate it! 🙏")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.5))
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial.opacity(0.4))
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            LinearGradient(
                                colors: [theme.primary.opacity(0.6), theme.primary.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            )
            .padding(.horizontal, theme.spacing.lg)
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 15)
            .animation(.easeOut(duration: 0.5).delay(0.2), value: animateIn)
        }
    }

    // MARK: - Phase 2: Thank You (brief, then prompt)
    private var thankYouPhase: some View {
        VStack(spacing: theme.spacing.lg) {
            // Checkmark success
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                theme.primary.opacity(0.3),
                                theme.primary.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(theme.primary.opacity(0.2))
                    .frame(width: 90, height: 90)
                    .overlay(
                        Circle()
                            .stroke(theme.primary.opacity(0.5), lineWidth: 2)
                    )

                Image(systemName: "heart.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(theme.primary)
                    .shadow(color: theme.primary.opacity(0.5), radius: 12)
            }

            Text("You're a legend! 🙌")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            Text("Tap 5 stars on the popup!")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.textSecondary)
        }
    }

    // MARK: - Trigger iOS Rating Prompt
    private func triggerRatingPrompt() {
        guard !hasRequestedReview else { return }

        // Track STY Validation step 6 - iOS rating popup shown
        STYValidationAnalytics.trackRatingShown()

        requestReview()
        hasRequestedReview = true
        UserDefaults.standard.set(true, forKey: "hasRequestedInlineReview")
        UserDefaults.standard.set(true, forKey: "hasRatedDuringOnboarding")
        print("⭐ [AppRatingScreen] Native iOS review prompt triggered after user commitment")
    }
}
