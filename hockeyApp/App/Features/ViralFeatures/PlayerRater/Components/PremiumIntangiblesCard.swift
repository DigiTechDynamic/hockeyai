import SwiftUI

// MARK: - Premium Intangibles Card
/// Shows premium STY Check insights with blur effect when locked
struct PremiumIntangiblesCard: View {
    @Environment(\.theme) var theme

    let premiumData: PremiumIntangibles?
    let isUnlocked: Bool
    let onUnlock: () -> Void

    @State private var showContent = false

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            // Header (benefit-focused, hockey culture authentic)
            VStack(alignment: .leading, spacing: 6) {
                Text("THE BEAUTY CHECK")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(theme.primary)
                    .tracking(1.2)

                if !isUnlocked {
                    Text("See what makes you a beauty on the ice")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.text)
                        .lineSpacing(2)
                }
            }
            .padding(.bottom, 4)

            if let data = premiumData {
                if isUnlocked {
                    // Show full unlocked content
                    UnlockedIntangiblesView(data: data)
                } else {
                    // Show large locked preview with upsell
                    BlurredIntangiblesView(data: data, onUnlock: onUnlock)
                }
            } else {
                // No premium data available (non-person photo)
                Text("Premium analysis only available for photos with a person.")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textSecondary)
                    .padding()
            }
        }
        .padding(theme.spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.cardBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [theme.primary.opacity(0.3), theme.primary.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                showContent = true
            }
        }
    }
}

// MARK: - Unlocked Intangibles View
struct UnlockedIntangiblesView: View {
    @Environment(\.theme) var theme
    let data: PremiumIntangibles

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            // Confidence
            IntangibleMetric(
                emoji: "💪",
                label: "Confidence",
                score: data.confidenceScore,
                explanation: data.confidenceExplanation
            )

            Divider().background(theme.textSecondary.opacity(0.2))

            // Toughness
            IntangibleMetric(
                emoji: "🥊",
                label: "Toughness",
                score: data.toughnessScore,
                explanation: data.toughnessExplanation
            )

            Divider().background(theme.textSecondary.opacity(0.2))

            // Flow
            IntangibleMetric(
                emoji: "✨",
                label: "Hockey Flow",
                score: data.flowScore,
                explanation: data.flowExplanation
            )

            Divider().background(theme.textSecondary.opacity(0.2))

            // Locker Room Nickname
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("🏒")
                        .font(.system(size: 18))
                    Text("Locker Room Nickname")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.text)
                }

                Text("\"\(data.lockerRoomNickname)\"")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.primary)

                Text(data.nicknameExplanation)
                    .font(.system(size: 13))
                    .foregroundColor(theme.textSecondary)
                    .lineSpacing(4)
            }

            Divider().background(theme.textSecondary.opacity(0.2))

            // Pro Comparison
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("⭐")
                        .font(.system(size: 18))
                    Text("You Remind Us Of")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.text)
                }

                Text(data.proComparison)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.primary)

                Text(data.proComparisonExplanation)
                    .font(.system(size: 13))
                    .foregroundColor(theme.textSecondary)
                    .lineSpacing(4)
            }

            Divider().background(theme.textSecondary.opacity(0.2))

            // Intimidation
            IntangibleMetric(
                emoji: "😤",
                label: "Intimidation Factor",
                score: data.intimidationScore,
                explanation: data.intimidationExplanation
            )
        }
    }
}

// MARK: - Blurred Intangibles View (Large locked preview with upsell)
struct BlurredIntangiblesView: View {
    @Environment(\.theme) var theme
    let data: PremiumIntangibles
    let onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Blurred preview sections to show what they're missing
            VStack(alignment: .leading, spacing: 20) {
                // Section 1: Your Hidden Stats (blurred)
                lockedSection(
                    emoji: "📊",
                    title: "YOUR HIDDEN STATS",
                    color: theme.primary,
                    previewLines: [
                        ("💪", "Confidence", "\(data.confidenceScore)/100"),
                        ("✨", "Hockey Flow", "\(data.flowScore)/100"),
                        ("🥊", "Toughness", "\(data.toughnessScore)/100"),
                        ("😤", "Intimidation", "\(data.intimidationScore)/100")
                    ]
                )

                Divider().background(Color.white.opacity(0.1))

                // Section 2: Locker Room Identity (blurred)
                lockedSection2(
                    emoji: "🏒",
                    title: "LOCKER ROOM IDENTITY",
                    color: .orange,
                    previewItems: [
                        ("Your Nickname", "\"\(data.lockerRoomNickname)\""),
                        ("Why It Fits", data.nicknameExplanation)
                    ]
                )

                Divider().background(Color.white.opacity(0.1))

                // Section 3: Pro Comparison (blurred)
                lockedSection2(
                    emoji: "⭐",
                    title: "YOUR PRO COMPARISON",
                    color: .yellow,
                    previewItems: [
                        ("You Remind Us Of", data.proComparison),
                        ("Because", data.proComparisonExplanation)
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

                        Text("Premium Insights Locked")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        Text("Unlock to reveal your full beauty check")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
            )

            // Feature list
            VStack(spacing: 14) {
                featureRowLarge(icon: "checkmark.circle.fill", text: "6 hidden strength scores")
                featureRowLarge(icon: "checkmark.circle.fill", text: "Your locker room nickname")
                featureRowLarge(icon: "checkmark.circle.fill", text: "NHL pro player comparison")
                featureRowLarge(icon: "checkmark.circle.fill", text: "Detailed explanations for each")
            }

            // Unlock button
            Button(action: onUnlock) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .bold))
                    Text("Reveal My Beauty Check")
                        .font(.system(size: 18, weight: .bold))
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(theme.primary.cornerRadius(16))
            }
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

    private func lockedSection(emoji: String, title: String, color: Color, previewLines: [(String, String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(color)
                    .tracking(1.2)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(previewLines, id: \.1) { item in
                    HStack(spacing: 10) {
                        Text(item.0)
                            .font(.system(size: 14))
                        Text(item.1)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Text(item.2)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(theme.primary.opacity(0.6))
                    }
                    .blur(radius: 4)
                }
            }
        }
    }

    private func lockedSection2(emoji: String, title: String, color: Color, previewItems: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(color)
                    .tracking(1.2)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(previewItems, id: \.0) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.0)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                        Text(item.1)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                    }
                    .blur(radius: 4)
                }
            }
        }
    }
}

// MARK: - Intangible Metric
struct IntangibleMetric: View {
    @Environment(\.theme) var theme

    let emoji: String
    let label: String
    let score: Int
    let explanation: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 18))

                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.text)

                Spacer()

                Text("\(score)/100")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(scoreColor(for: score))
            }

            Text(explanation)
                .font(.system(size: 13))
                .foregroundColor(theme.textSecondary)
                .lineSpacing(4)
        }
    }

    private func scoreColor(for score: Int) -> Color {
        switch score {
        case 90...100: return .green
        case 75..<90: return theme.primary
        case 60..<75: return .orange
        default: return .red
        }
    }
}

// MARK: - Locked Metric Row (Simple row for blur layer)
struct LockedMetricRow: View {
    @Environment(\.theme) var theme

    let emoji: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 16))

            Text("\(label):")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.text)

            Spacer()

            // Value will be blurred by parent view
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(theme.primary)
        }
    }
}

