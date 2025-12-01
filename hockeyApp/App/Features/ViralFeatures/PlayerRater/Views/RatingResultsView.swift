import SwiftUI
import UIKit

// MARK: - Rating Results View (Face-aware, modern)
struct RatingResultsView: View {
    @Environment(\.theme) var theme
    @ObservedObject var viewModel: PlayerRaterViewModel

    @State private var showContent = false
    @State private var imageScale: CGFloat = 1.1
    @State private var displayScore: Int = 0
    @State private var scoreTimer: Timer?
    @State private var hasSavedResult = false

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            // Make content scrollable and eliminate layout-expanding spacers
            ScrollView(showsIndicators: false) {
                // Tighter vertical rhythm to remove perceived gap under the hero image
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    // Top section with score overlay and face-aware centering (Option 2)
                    if let rating = viewModel.rating, let image = viewModel.uploadedImage {
                        ScoreCardOverlayImage(
                            image: image,
                            score: displayScore,
                            archetype: rating.archetype,
                            imageScale: imageScale,
                            isOnboarding: viewModel.context == .onboarding
                        )
                        .onAppear { startScoreAnimation(to: rating.overallScore) }
                    }

                    if let rating = viewModel.rating {
                        // Onboarding: Show simple "you're in" message
                        if viewModel.context == .onboarding {
                            VStack(spacing: theme.spacing.md) {
                                Text("You're in! 🎉")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)

                                Text("Full STY Check, Skill Check, and Training are now unlocked.")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(theme.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, theme.spacing.lg)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 10)

                            // AI Comment Card (show in onboarding too)
                            if let comment = rating.aiComment {
                                AICommentCard(comment: comment, showContent: showContent)
                                    .padding(.top, 8)
                            }
                        } else {
                            // Regular STY Check: Show full breakdown
                            TierBadgeCard(
                                score: rating.overallScore,
                                archetype: rating.archetype,
                                archetypeEmoji: rating.archetypeEmoji,
                                showContent: showContent,
                                isCompact: true
                            )

                            // AI Comment Card
                            if let comment = rating.aiComment {
                                AICommentCard(comment: comment, showContent: showContent)
                                    .padding(.top, 8)
                            } else {
                                // DEBUG: Show why comment is missing
                                Text("DEBUG: aiComment is nil")
                                    .foregroundColor(.red)
                                    .padding(.top, 8)
                            }
                        }


                        // Premium Intangibles Card (HIDDEN during onboarding - keep flow tight for launch)
                        if viewModel.context != .onboarding {
                            PremiumIntangiblesCard(
                                premiumData: rating.premiumIntangibles,
                                isUnlocked: viewModel.isPremiumUnlocked,
                                onUnlock: viewModel.unlockPremium
                            )
                            .padding(.top, 8)
                        }

                        // Action Buttons
                        VStack(spacing: 12) {
                            // Onboarding: Single continue button
                            // Regular: New STY Check + Done buttons (matches SavedSTYCheckResultsView)
                            if viewModel.context == .onboarding {
                                Button(action: {
                                    viewModel.complete()
                                }) {
                                    Text("Continue")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(theme.background)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 52)
                                        .background(theme.primary)
                                        .cornerRadius(14)
                                }
                            } else {
                                // New Check button (primary)
                                Button(action: {
                                    viewModel.startNewCheck()
                                }) {
                                    HStack {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 16, weight: .bold))
                                        Text("New STY Check")
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                    .foregroundColor(theme.background)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(theme.primary)
                                    .cornerRadius(14)
                                }

                                // Done button (secondary)
                                Button(action: {
                                    // Track completion
                                    if let rating = viewModel.rating {
                                        STYCheckAnalytics.trackCompletedWithoutPremium(
                                            score: rating.overallScore,
                                            tier: rating.archetype
                                        )
                                    }
                                    viewModel.complete()
                                }) {
                                    Text("Done")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(theme.text)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 52)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(theme.textSecondary.opacity(0.3), lineWidth: 1.5)
                                        )
                                }
                            }
                        }
                        .padding(.top, theme.spacing.md)
                    }

                    // Bottom safe area padding
                    Color.clear.frame(height: theme.spacing.xl)
                }
                .padding(.horizontal, theme.spacing.lg)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { imageScale = 1.0 }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) { showContent = true }

            // Track results viewed
            if let rating = viewModel.rating {
                if viewModel.context == .onboarding {
                    // Onboarding STY Validation funnel (step 4 - results viewed)
                    STYValidationAnalytics.trackResultsViewed(
                        score: rating.overallScore,
                        tier: rating.archetype
                    )
                } else {
                    // Post-onboarding STY Home funnel (step 5 - results viewed)
                    STYCheckAnalytics.trackResultsViewed(
                        score: rating.overallScore,
                        tier: rating.archetype
                    )
                }

                // Save result to history (only once per view, skip onboarding)
                if !hasSavedResult && viewModel.context != .onboarding {
                    hasSavedResult = true
                    AnalysisResultsStore.shared.saveSTYCheckResult(rating, photo: viewModel.uploadedImage)
                }
            }

            // Check if user is already premium
            viewModel.checkPremiumStatus()
        }
        .onDisappear { scoreTimer?.invalidate(); scoreTimer = nil }
        .fullScreenCover(isPresented: $viewModel.showPaywall) {
            PaywallPresenter(source: "player_rater_beauty_check")
                .preferredColorScheme(.dark)
                .onDisappear {
                    // Check if user purchased after paywall dismisses
                    viewModel.checkPremiumStatus()
                }
        }
    }

    private func startScoreAnimation(to target: Int) {
        scoreTimer?.invalidate()
        displayScore = 0
        guard target > 0 else { return }
        let interval = 0.012
        scoreTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            if displayScore < target {
                displayScore += 1
                if displayScore % 5 == 0 { HapticManager.shared.playSelection() }
            } else {
                timer.invalidate()
                scoreTimer = nil

                // Celebration for final score reveal (haptics only)
                HapticManager.shared.playImpact(style: .heavy)
                HapticManager.shared.playNotification(type: .success)
            }
        }
        RunLoop.main.add(scoreTimer!, forMode: .common)
    }

}
