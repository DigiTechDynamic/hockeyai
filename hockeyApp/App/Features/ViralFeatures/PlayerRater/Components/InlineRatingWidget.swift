import SwiftUI
import StoreKit

// MARK: - Inline Rating Widget (Optimized for 4.5+ Stars)
/// Uses sentiment check to route happy users to App Store, others to feedback
/// This maximizes App Store rating while collecting actionable feedback
struct InlineRatingWidget: View {
    @Environment(\.theme) private var theme
    @Environment(\.requestReview) private var requestReview

    /// Called when user completes rating action
    var onRated: (() -> Void)? = nil

    @State private var hasCompleted: Bool = false
    @State private var showFeedbackForm: Bool = false
    @State private var animateIn = false
    @State private var showThankYou = false

    var body: some View {
        if !hasCompleted {
            if !showThankYou {
                // Main sentiment check card
                sentimentCheckCard
            } else {
                // Thank you card (brief)
                thankYouCard
            }
        }
    }

    // MARK: - Sentiment Check Card
    private var sentimentCheckCard: some View {
        VStack(spacing: theme.spacing.xl) {
            // Icon
            Image(systemName: "hand.thumbsup.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(theme.primary)
                .opacity(animateIn ? 1 : 0)
                .scaleEffect(animateIn ? 1.0 : 0.8)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animateIn)

            // Title
            VStack(spacing: theme.spacing.sm) {
                Text("Enjoying Hockey AI?")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 10)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: animateIn)

                Text("Your feedback helps us improve the app for all players")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: animateIn)
            }

            // Sentiment buttons
            VStack(spacing: theme.spacing.md) {
                // Positive sentiment (triggers App Store review)
                Button(action: handlePositiveSentiment) {
                    HStack(spacing: 10) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 18, weight: .bold))

                        Text("Yes, loving it!")
                            .font(.system(size: 17, weight: .bold))

                        Image(systemName: "face.smiling.fill")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [theme.primary, theme.primary.opacity(0.9)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: theme.primary.opacity(0.4), radius: 12, y: 6)
                }
                .buttonStyle(ScaleButtonStyle())

                // Negative sentiment (opens feedback form)
                Button(action: handleNegativeSentiment) {
                    HStack(spacing: 8) {
                        Image(systemName: "bubble.left.fill")
                            .font(.system(size: 16, weight: .semibold))

                        Text("Not yet, but I have feedback")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(theme.text)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(theme.divider.opacity(0.3), lineWidth: 1.5)
                            )
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .opacity(animateIn ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.3), value: animateIn)

            // Not now button
            Button(action: dismissWidget) {
                Text("Not now")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.textSecondary.opacity(0.6))
                    .frame(height: 44)
            }
            .opacity(animateIn ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.4), value: animateIn)
        }
        .padding(.vertical, theme.spacing.xl)
        .padding(.horizontal, theme.spacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(theme.primary.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear {
            // Delay appearance until after score animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation {
                    animateIn = true
                }
            }
        }
        .sheet(isPresented: $showFeedbackForm) {
            FeedbackFormView(onSubmit: handleFeedbackSubmission)
                .preferredColorScheme(.dark)
        }
    }

    // MARK: - Thank You Card
    private var thankYouCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(theme.primary)

            Text("Thanks for your feedback! 🏒")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.text)

            Spacer()
        }
        .padding(theme.spacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.primary.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.primary.opacity(0.3), lineWidth: 1)
                )
        )
        .transition(.scale.combined(with: .opacity))
        .onAppear {
            // Auto-hide after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    hasCompleted = true
                }
            }
        }
    }

    // MARK: - Actions

    private func handlePositiveSentiment() {
        HapticManager.shared.playNotification(type: .success)

        // Trigger native iOS review prompt
        requestReview()

        // Mark as completed to skip full-screen rating later
        UserDefaults.standard.set(true, forKey: "hasRequestedInlineReview")

        // Show thank you briefly
        withAnimation(.easeOut(duration: 0.3)) {
            showThankYou = true
        }

        // Save positive sentiment
        saveSentiment(isPositive: true)

        onRated?()

        print("✅ [InlineRatingWidget] Positive sentiment - iOS review prompt triggered")
    }

    private func handleNegativeSentiment() {
        HapticManager.shared.playImpact(style: .medium)

        // Open feedback form
        showFeedbackForm = true

        // Save negative sentiment (but don't mark as completed yet - wait for feedback)
        saveSentiment(isPositive: false)

        print("📝 [InlineRatingWidget] Negative sentiment - opening feedback form")
    }

    private func handleFeedbackSubmission(_ submission: FeedbackSubmission) {
        // Save feedback
        saveFeedback(submission)

        // Mark as completed
        UserDefaults.standard.set(true, forKey: "hasRequestedInlineReview")

        // Show thank you
        showFeedbackForm = false
        withAnimation(.easeOut(duration: 0.3)) {
            showThankYou = true
        }

        onRated?()

        print("✅ [InlineRatingWidget] Feedback submitted: \(submission.category.rawValue)")
    }

    private func dismissWidget() {
        HapticManager.shared.playImpact(style: .light)

        // Mark as dismissed (widget won't show again)
        UserDefaults.standard.set(true, forKey: "inlineRatingDismissedDuringOnboarding")

        withAnimation(.easeOut(duration: 0.3)) {
            hasCompleted = true
        }

        print("⏭️ [InlineRatingWidget] Dismissed by user")
    }

    // MARK: - Helpers

    private func saveSentiment(isPositive: Bool) {
        var sentiments = UserDefaults.standard.array(forKey: "userSentiments") as? [[String: Any]] ?? []
        let sentiment: [String: Any] = [
            "isPositive": isPositive,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "context": "onboarding_sty_check"
        ]
        sentiments.append(sentiment)
        UserDefaults.standard.set(sentiments, forKey: "userSentiments")
    }

    private func saveFeedback(_ submission: FeedbackSubmission) {
        var feedbacks = UserDefaults.standard.array(forKey: "userFeedback") as? [[String: Any]] ?? []
        feedbacks.append(submission.dictionary)
        UserDefaults.standard.set(feedbacks, forKey: "userFeedback")

        // Also log to console for now
        print("📝 Feedback saved:")
        print("   Category: \(submission.category.title)")
        if let text = submission.text {
            print("   Text: \(text)")
        }
    }
}

// MARK: - Preview
struct InlineRatingWidget_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            InlineRatingWidget(onRated: {
                print("User completed rating flow")
            })
        }
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
