import SwiftUI
import AVKit
import AVFoundation

// MARK: - Skill Check Results View
/// STY Check style results with looping video and Greeny's comment
struct SkillCheckResultsView: View {
    @Environment(\.theme) var theme
    let analysisResult: SkillAnalysisResult?
    let onExit: () -> Void

    @State private var showContent = false
    @State private var displayScore: Int = 0
    @State private var scoreTimer: Timer?
    @State private var showPaywall = false
    @State private var isPremiumUnlocked = false

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    // Top section with looping video and score overlay
                    if let result = analysisResult {
                        VideoScoreCard(
                            videoURL: result.videoURL,
                            score: displayScore,
                            category: result.category ?? "Skill",
                            showContent: showContent
                        )
                        .onAppear { startScoreAnimation(to: result.overallScore) }

                        // Greeny's AI Comment Card
                        SkillCheckCommentCard(
                            comment: result.aiComment,
                            showContent: showContent
                        )
                        .padding(.top, 8)

                        // Premium "The Elite Breakdown" Card
                        PremiumEliteBreakdownCard(
                            breakdown: result.premiumBreakdown,
                            showContent: showContent,
                            isUnlocked: isPremiumUnlocked,
                            onUnlock: unlockPremium
                        )
                        .padding(.top, 8)

                        // Done button
                        Button(action: onExit) {
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
                        .padding(.top, theme.spacing.md)
                    }

                    // Bottom safe area padding
                    Color.clear.frame(height: theme.spacing.xl)
                }
                .padding(.horizontal, theme.spacing.lg)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showContent = true
            }

            // Track results viewed (Step 6)
            if let result = analysisResult {
                let tier = getTierLabel(for: result.overallScore)
                SkillCheckAnalytics.trackResultsViewed(
                    score: result.overallScore,
                    tier: tier,
                    category: result.category
                )
            }

            checkPremiumStatus()
        }
        .onDisappear {
            scoreTimer?.invalidate()
            scoreTimer = nil
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallPresenter(source: "skill_check_breakdown")
                .preferredColorScheme(.dark)
                .onAppear {
                    // Track paywall shown
                    if let result = analysisResult {
                        let tier = getTierLabel(for: result.overallScore)
                        AnalyticsManager.shared.track(
                            eventName: "skill_check_paywall_shown",
                            properties: [
                                "source": "breakdown_reveal",
                                "score": result.overallScore,
                                "tier": tier
                            ]
                        )

                        #if DEBUG
                        print("📊 [Skill Check] Paywall shown - Source: breakdown_reveal, Score: \(result.overallScore)")
                        #endif
                    }
                }
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

                // Celebration haptics
                HapticManager.shared.playImpact(style: .heavy)
                HapticManager.shared.playNotification(type: .success)
            }
        }
        RunLoop.main.add(scoreTimer!, forMode: .common)
    }

    // MARK: - Premium Actions

    private func unlockPremium() {
        // Track breakdown reveal clicked (Step 7)
        if let result = analysisResult {
            let tier = getTierLabel(for: result.overallScore)
            SkillCheckAnalytics.trackEliteBreakdownClicked(
                score: result.overallScore,
                tier: tier,
                category: result.category
            )
        }

        showPaywall = true
        HapticManager.shared.playImpact(style: .medium)
        print("💎 [SkillCheckResultsView] Triggering breakdown paywall")
    }

    private func checkPremiumStatus() {
        let monetization = MonetizationManager.shared

        if monetization.isPremium {
            let wasAlreadyUnlocked = isPremiumUnlocked
            isPremiumUnlocked = true
            HapticManager.shared.playNotification(type: .success)
            print("✅ [SkillCheckResultsView] Premium purchased - breakdown unlocked!")

            // Track breakdown unlocked (Step 8 - Funnel Completion)
            if !wasAlreadyUnlocked, let result = analysisResult {
                let tier = getTierLabel(for: result.overallScore)
                SkillCheckAnalytics.trackEliteBreakdownUnlocked(
                    score: result.overallScore,
                    tier: tier,
                    category: result.category
                )
            }
        } else {
            print("❌ [SkillCheckResultsView] Not premium")
        }
    }

    // MARK: - Helper Methods

    /// Get tier label based on score (matches VideoScoreCard logic)
    private func getTierLabel(for score: Int) -> String {
        switch score {
        case 90...100: return "ELITE"
        case 80..<90: return "SOLID"
        case 70..<80: return "GOOD"
        case 60..<70: return "DECENT"
        case 50..<60: return "AVERAGE"
        default: return "DEVELOPING"
        }
    }
}

// MARK: - Video Score Card Component
/// Displays looping video with score overlay at bottom (STY Check style)
struct VideoScoreCard: View {
    @Environment(\.theme) var theme
    let videoURL: URL?
    let score: Int
    let category: String
    let showContent: Bool

    @State private var player: AVPlayer?
    @State private var showCard = false

    // Helper for consistent container height
    private var containerHeight: CGFloat {
        max(min(UIScreen.main.bounds.height * 0.40, 360), 200)
    }

    // Get tier label based on score
    private var tierLabel: String {
        switch score {
        case 90...100: return "ELITE"
        case 80..<90: return "SOLID"
        case 70..<80: return "GOOD"
        case 60..<70: return "DECENT"
        case 50..<60: return "AVERAGE"
        default: return "DEVELOPING"
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Video player
                if let videoURL = videoURL, let player = player {
                    VideoPlayer(player: player)
                        .disabled(true)
                        .frame(width: geometry.size.width, height: containerHeight)
                        .onAppear {
                            configureAudioSession()
                            player.isMuted = true
                            player.volume = 0.0
                            player.play()
                            player.actionAtItemEnd = .none

                            // Loop video
                            NotificationCenter.default.addObserver(
                                forName: .AVPlayerItemDidPlayToEndTime,
                                object: player.currentItem,
                                queue: .main
                            ) { _ in
                                player.seek(to: .zero)
                                player.play()
                            }
                        }
                } else {
                    // Fallback color if no video
                    Color.black
                        .frame(height: containerHeight)
                        .onAppear {
                            loadVideo()
                        }
                }

                // Bottom gradient for card readability
                LinearGradient(
                    colors: [
                        .clear,
                        .black.opacity(0.1),
                        .black.opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: containerHeight * 0.35)

                // Frosted glass score card at bottom
                HStack(spacing: 16) {
                    // Score
                    Text("\(score)")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: theme.primary.opacity(0.6), radius: 12)

                    // Divider
                    Rectangle()
                        .fill(theme.primary.opacity(0.4))
                        .frame(width: 2, height: 40)

                    // Tier info
                    Text(tierLabel.uppercased())
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.white)
                        .tracking(1.5)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    ZStack {
                        // Frosted glass effect
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)

                        // Dark tint
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.3))

                        // Green accent border
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(theme.primary.opacity(0.5), lineWidth: 1.5)
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .scaleEffect(showCard ? 1.0 : 0.9)
                .opacity(showCard ? 1.0 : 0)
                .offset(y: showCard ? 0 : 20)
            }
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                // Full-perimeter gradient border
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [theme.primary.opacity(0.9), theme.accent.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 4
                    )
                    .shadow(color: theme.primary.opacity(0.45), radius: 10, y: 5)
            )
            .overlay(
                // Subtle glow around entire card
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(theme.primary.opacity(0.25), lineWidth: 8)
                    .blur(radius: 10)
            )
            .frame(height: containerHeight)
            .ignoresSafeArea(edges: .top)
        }
        .frame(height: containerHeight)
        .onAppear {
            // Animate card in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showCard = true
                }
            }
        }
    }

    private func loadVideo() {
        guard let videoURL = videoURL else { return }
        player = AVPlayer(url: videoURL)
        player?.isMuted = true
        player?.volume = 0.0
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
}

// MARK: - Premium Elite Breakdown Card (Viral-Optimized)
/// New viral-focused premium breakdown with style metrics, viral potential, and identity
private struct PremiumEliteBreakdownCard: View {
    @Environment(\.theme) var theme
    let breakdown: PremiumSkillBreakdown
    let showContent: Bool
    let isUnlocked: Bool
    let onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("FULL BREAKDOWN")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundColor(theme.primary)
                    .tracking(1.5)

                Text(isUnlocked ? "Your personalized feedback" : "See what the AI really found")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            if isUnlocked {
                // Unlocked content - actionable feedback
                VStack(alignment: .leading, spacing: 20) {
                    // 1. WHAT YOU DID WELL
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.green)
                            Text("WHAT YOU DID WELL")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(.green)
                                .tracking(1.2)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(breakdown.whatYouDidWell, id: \.self) { item in
                                feedbackRow(text: item, color: .green)
                            }
                        }
                    }

                    Divider().background(Color.white.opacity(0.1))

                    // 2. WHAT TO WORK ON
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.orange)
                            Text("WHAT TO WORK ON")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(.orange)
                                .tracking(1.2)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(breakdown.whatToWorkOn, id: \.self) { item in
                                feedbackRow(text: item, color: .orange)
                            }
                        }
                    }

                    Divider().background(Color.white.opacity(0.1))

                    // 3. HOW TO IMPROVE
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 18))
                                .foregroundColor(theme.primary)
                            Text("HOW TO IMPROVE")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(theme.primary)
                                .tracking(1.2)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(breakdown.howToImprove, id: \.self) { item in
                                drillRow(text: item)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            } else {
                // Locked content preview
                ZStack {
                    // Blurred background with hints
                    VStack(alignment: .leading, spacing: 8) {
                        Text("✓ Great weight transfer from back to...")
                            .blur(radius: 6)
                        Text("✓ Smooth stick flex on the release...")
                            .blur(radius: 6)
                        Text("△ Keep elbow higher during...")
                            .blur(radius: 6)
                        Text("△ Bend knees more for better...")
                            .blur(radius: 6)
                        Text("◆ Wall shots - 50 reps daily...")
                            .blur(radius: 6)
                        Text("◆ One-knee wrist shots to isolate...")
                            .blur(radius: 6)
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 150)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(theme.primary.opacity(0.3), lineWidth: 1.5)
                            )
                    )

                    // Lock overlay
                    VStack(spacing: 16) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 36))
                            .foregroundColor(theme.primary)

                        VStack(spacing: 12) {
                            featureRow(icon: "checkmark.circle.fill", text: "Technique analysis")
                            featureRow(icon: "checkmark.circle.fill", text: "What to improve")
                            featureRow(icon: "checkmark.circle.fill", text: "Drills to practice")
                        }
                    }
                }
                .padding(.horizontal, 20)

                // Unlock button
                Button(action: onUnlock) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 16, weight: .semibold))

                        Text("Unlock Full Breakdown")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [theme.primary, theme.primary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .cornerRadius(14)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
            }
        }
        .background(
            ZStack {
                // Dark base
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.15, green: 0.15, blue: 0.15))

                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.03),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Green accent border
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(theme.primary.opacity(0.4), lineWidth: 2)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: theme.primary.opacity(0.2), radius: 16, y: 8)
        .shadow(color: Color.black.opacity(0.4), radius: 24, y: 12)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 15)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.primary)

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
        }
    }

    private func feedbackRow(text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .padding(.top, 6)

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func drillRow(text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 12))
                .foregroundColor(theme.primary)
                .padding(.top, 3)

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Score Metric Row Helper
private struct ScoreMetricRow: View {
    @Environment(\.theme) var theme

    let emoji: String
    let label: String
    let score: Int

    private var scoreColor: Color {
        switch score {
        case 90...100: return .green
        case 75..<90: return theme.primary
        case 60..<75: return .orange
        default: return .red
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 16))

            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            Spacer()

            Text("\(score)/100")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(scoreColor)
        }
    }
}

// MARK: - Skill Check Comment Card (Greeny's Comment)
/// Viral-optimized comment card with neon green accent and glass morphism
private struct SkillCheckCommentCard: View {
    @Environment(\.theme) var theme
    let comment: String
    let showContent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Greeny profile + name
            HStack(spacing: 10) {
                // Greeny profile pic
                Image("GreenyProfilePic")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(theme.primary.opacity(0.3), lineWidth: 1.5)
                    )

                Text("Greeny")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Divider
            Rectangle()
                .fill(theme.primary.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 18)

            // Comment text
            Text(comment)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.95))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
        }
        .background(
            ZStack {
                // Darker base for better contrast
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.black.opacity(0.6))

                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Glass effect
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial.opacity(0.5))

                // Green accent border
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                theme.primary.opacity(0.6),
                                theme.primary.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: theme.primary.opacity(0.2), radius: 16, y: 8)
        .shadow(color: Color.black.opacity(0.4), radius: 24, y: 12)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 15)
    }
}

// MARK: - Preview
#Preview {
    SkillCheckResultsView(
        analysisResult: SkillAnalysisResult(
            confidence: 0.95,
            overallScore: 88,
            category: "Shooting",
            aiComment: "That wrist shot release is buttery smooth! You're out here making goalies look silly. Keep that top hand loose and you'll be unstoppable!",
            premiumBreakdown: .placeholder,
            videoURL: nil,
            analysisMetadata: VideoAnalysisMetadata(
                videoDuration: 3.0,
                videoResolution: CGSize(width: 1920, height: 1080),
                videoFileSize: 1024000,
                processingTime: 5.0,
                selectedShotType: ""
            )
        ),
        onExit: {}
    )
    .preferredColorScheme(.dark)
}
