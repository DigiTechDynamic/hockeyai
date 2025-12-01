import SwiftUI
import AVKit
import AVFoundation

// MARK: - Saved Skill Check Results View
/// Shows previously saved Skill Check results with option to do a new check
struct SavedSkillCheckResultsView: View {
    @Environment(\.theme) var theme
    let result: StoredSkillCheckResult
    let onNewCheck: () -> Void
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
                    // Header (no close button - user must scroll to bottom)
                    Text("Your Results")
                        .font(.system(size: 20, weight: .black))
                        .glowingHeaderText()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)

                    // Video with score overlay
                    if let videoURL = AnalysisResultsStore.shared.loadSkillVideoURL(for: result) {
                        VideoScoreCard(
                            videoURL: videoURL,
                            score: displayScore,
                            category: result.category ?? "Skill",
                            showContent: showContent
                        )
                        .onAppear { startScoreAnimation(to: result.overallScore) }
                    } else if let thumbnail = AnalysisResultsStore.shared.loadSkillThumbnail(for: result) {
                        // Fallback to thumbnail with score overlay
                        ThumbnailScoreCard(
                            thumbnail: thumbnail,
                            score: displayScore,
                            category: result.category ?? "Skill",
                            showContent: showContent
                        )
                        .onAppear { startScoreAnimation(to: result.overallScore) }
                    }

                    // Greeny's AI Comment Card
                    SkillCheckCommentCardPublic(
                        comment: result.aiComment,
                        showContent: showContent
                    )
                    .padding(.top, 8)

                    // Premium "The Elite Breakdown" Card
                    PremiumEliteBreakdownCardPublic(
                        breakdown: result.premiumBreakdown,
                        showContent: showContent,
                        isUnlocked: isPremiumUnlocked,
                        onUnlock: unlockPremium
                    )
                    .padding(.top, 8)

                    // Action Buttons
                    VStack(spacing: 12) {
                        // New Check button (primary)
                        Button(action: onNewCheck) {
                            HStack {
                                Image(systemName: "video.fill")
                                    .font(.system(size: 16, weight: .bold))
                                Text("New Skill Check")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(theme.background)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(theme.primary)
                            .cornerRadius(14)
                        }

                        // Done button (secondary)
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
                    }
                    .padding(.top, theme.spacing.md)

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
            checkPremiumStatus()
        }
        .onDisappear {
            scoreTimer?.invalidate()
            scoreTimer = nil
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallPresenter(source: "skill_check_saved_results")
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

// MARK: - Thumbnail Score Card
/// Shows a static thumbnail with score overlay (when video not available)
private struct ThumbnailScoreCard: View {
    @Environment(\.theme) var theme
    let thumbnail: UIImage
    let score: Int
    let category: String
    let showContent: Bool

    @State private var showCard = false

    private var containerHeight: CGFloat {
        max(min(UIScreen.main.bounds.height * 0.40, 360), 200)
    }

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
                // Thumbnail image
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: containerHeight)
                    .clipped()

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
                    Text("\(score)")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: theme.primary.opacity(0.6), radius: 12)

                    Rectangle()
                        .fill(theme.primary.opacity(0.4))
                        .frame(width: 2, height: 40)

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
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.3))
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
            .frame(height: containerHeight)
        }
        .frame(height: containerHeight)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showCard = true
                }
            }
        }
    }
}

// MARK: - Skill Check Comment Card (for saved results)
struct SkillCheckCommentCardPublic: View {
    @Environment(\.theme) var theme
    let comment: String
    let showContent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
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

            Rectangle()
                .fill(theme.primary.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 18)

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
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.black.opacity(0.6))
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial.opacity(0.5))
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        LinearGradient(
                            colors: [theme.primary.opacity(0.6), theme.primary.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 15)
    }
}

// MARK: - Premium Elite Breakdown Card (for saved results)
struct PremiumEliteBreakdownCardPublic: View {
    @Environment(\.theme) var theme
    let breakdown: PremiumSkillBreakdown
    let showContent: Bool
    let isUnlocked: Bool
    let onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 0) {
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
                VStack(alignment: .leading, spacing: 20) {
                    feedbackSection(
                        icon: "checkmark.circle.fill",
                        title: "WHAT YOU DID WELL",
                        items: breakdown.whatYouDidWell,
                        color: .green
                    )

                    Divider().background(Color.white.opacity(0.1))

                    feedbackSection(
                        icon: "exclamationmark.triangle.fill",
                        title: "WHAT TO WORK ON",
                        items: breakdown.whatToWorkOn,
                        color: .orange
                    )

                    Divider().background(Color.white.opacity(0.1))

                    feedbackSection(
                        icon: "figure.strengthtraining.traditional",
                        title: "HOW TO IMPROVE",
                        items: breakdown.howToImprove,
                        color: theme.primary
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            } else {
                // Locked state - Large premium upsell section
                VStack(spacing: 24) {
                    // Blurred preview sections to show what they're missing
                    VStack(alignment: .leading, spacing: 20) {
                        // Section 1: What You Did Well (blurred)
                        lockedSection(
                            icon: "checkmark.circle.fill",
                            title: "WHAT YOU DID WELL",
                            color: .green,
                            previewLines: [
                                "Great weight transfer from back to front foot",
                                "Smooth stick flex on the release point",
                                "Good follow-through toward target"
                            ]
                        )

                        Divider().background(Color.white.opacity(0.1))

                        // Section 2: What To Work On (blurred)
                        lockedSection(
                            icon: "exclamationmark.triangle.fill",
                            title: "WHAT TO WORK ON",
                            color: .orange,
                            previewLines: [
                                "Keep elbow higher during wind-up",
                                "Bend knees more for better power",
                                "Rotate hips earlier in the motion"
                            ]
                        )

                        Divider().background(Color.white.opacity(0.1))

                        // Section 3: Drills (blurred)
                        lockedSection(
                            icon: "figure.strengthtraining.traditional",
                            title: "DRILLS TO PRACTICE",
                            color: theme.primary,
                            previewLines: [
                                "Wall shots - 50 reps daily focusing on release",
                                "One-knee wrist shots to isolate upper body",
                                "Stick flex drills against boards"
                            ]
                        )
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.3))
                    )
                    .overlay(
                        // Lock overlay
                        ZStack {
                            Color.black.opacity(0.4)

                            VStack(spacing: 16) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(theme.primary)

                                Text("Premium Analysis Locked")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)

                                Text("Unlock to see your personalized feedback")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    )
                    .padding(.horizontal, 20)

                    // Feature list
                    VStack(spacing: 14) {
                        featureRowLarge(icon: "checkmark.circle.fill", text: "Detailed technique analysis")
                        featureRowLarge(icon: "checkmark.circle.fill", text: "Personalized improvement tips")
                        featureRowLarge(icon: "checkmark.circle.fill", text: "Custom practice drills")
                        featureRowLarge(icon: "checkmark.circle.fill", text: "Track progress over time")
                    }
                    .padding(.horizontal, 20)

                    // Unlock button
                    Button(action: onUnlock) {
                        HStack(spacing: 10) {
                            Image(systemName: "lock.open.fill")
                                .font(.system(size: 18, weight: .bold))
                            Text("Unlock Full Breakdown")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(theme.primary.cornerRadius(16))
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
            }
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(theme.primary.opacity(0.4), lineWidth: 2)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
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

    private func featureRowLarge(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(theme.primary)
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            Spacer()
        }
    }

    private func lockedSection(icon: String, title: String, color: Color, previewLines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(color)
                    .tracking(1.2)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(previewLines, id: \.self) { line in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(color.opacity(0.5))
                            .frame(width: 5, height: 5)
                            .padding(.top, 6)
                        Text(line)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .blur(radius: 4)
                    }
                }
            }
        }
    }

    private func feedbackSection(icon: String, title: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(color)
                    .tracking(1.2)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        Text(item)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}
