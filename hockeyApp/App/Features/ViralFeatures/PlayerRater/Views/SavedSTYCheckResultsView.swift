import SwiftUI
import UIKit

// MARK: - Saved STY Check Results View
/// Shows previously saved STY Check results with option to do a new check
struct SavedSTYCheckResultsView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    let result: StoredSTYCheckResult
    let onNewCheck: () -> Void
    let onExit: () -> Void

    @State private var showContent = false
    @State private var imageScale: CGFloat = 1.1
    @State private var displayScore: Int = 0
    @State private var scoreTimer: Timer?
    @State private var showPaywall = false
    @State private var isPremiumUnlocked = false

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    // Header (no close button - user must scroll to bottom)
                    Text("Your Results")
                        .font(.system(size: 20, weight: .black))
                        .glowingHeaderText()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)

                    // Photo with score overlay
                    if let photo = AnalysisResultsStore.shared.loadSTYPhoto(for: result) {
                        ScoreCardOverlayImage(
                            image: photo,
                            score: displayScore,
                            archetype: result.archetype,
                            imageScale: imageScale,
                            isOnboarding: false
                        )
                        .onAppear { startScoreAnimation(to: result.overallScore) }
                    }

                    // Tier Badge Card
                    TierBadgeCard(
                        score: result.overallScore,
                        archetype: result.archetype,
                        archetypeEmoji: result.archetypeEmoji,
                        showContent: showContent,
                        isCompact: true
                    )

                    // AI Comment Card
                    if let comment = result.aiComment {
                        AICommentCard(comment: comment, showContent: showContent)
                            .padding(.top, 8)
                    }

                    // Premium Intangibles Card (if available)
                    if result.premiumIntangibles != nil {
                        PremiumIntangiblesCard(
                            premiumData: result.premiumIntangibles,
                            isUnlocked: isPremiumUnlocked,
                            onUnlock: unlockPremium
                        )
                        .padding(.top, 8)
                    }

                    // Action Buttons
                    VStack(spacing: 12) {
                        // New Check button (primary)
                        Button(action: onNewCheck) {
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
                            onExit()
                            dismiss()
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
                    .padding(.top, theme.spacing.md)

                    // Bottom safe area padding
                    Color.clear.frame(height: theme.spacing.xl)
                }
                .padding(.horizontal, theme.spacing.lg)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { imageScale = 1.0 }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) { showContent = true }
            checkPremiumStatus()
        }
        .onDisappear {
            scoreTimer?.invalidate()
            scoreTimer = nil
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallPresenter(source: "sty_check_saved_results")
                .preferredColorScheme(.dark)
                .onDisappear {
                    checkPremiumStatus()
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
                if displayScore % 5 == 0 {
                    HapticManager.shared.playSelection()
                }
            } else {
                timer.invalidate()
                scoreTimer = nil
                HapticManager.shared.playImpact(style: .heavy)
                HapticManager.shared.playNotification(type: .success)
            }
        }
        RunLoop.main.add(scoreTimer!, forMode: .common)
    }

    private func unlockPremium() {
        showPaywall = true
        HapticManager.shared.playImpact(style: .medium)
    }

    private func checkPremiumStatus() {
        isPremiumUnlocked = MonetizationManager.shared.isPremium
    }
}
