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
                    // Show blurred preview
                    VStack(spacing: theme.spacing.sm) {
                        BlurredIntangiblesView(data: data)

                        // Conversion strip (Social proof + Urgency) - CRITICAL FOR CONVERSION
                        VStack(spacing: 6) {
                            // Social proof with live indicator
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)

                                Text("2,847 players unlocked today")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(theme.text)
                            }

                            // Urgency message
                            Text("Limited time: Full beauty analysis available")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(theme.textSecondary)
                        }
                        .padding(.top, 4)

                        // Reveal button (Looksmax-style aspirational CTA)
                        Button(action: onUnlock) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16, weight: .semibold))

                                Text("Reveal My Beauty Check")
                                    .font(.system(size: 17, weight: .bold))

                                Image(systemName: "sparkles")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [
                                        theme.primary,
                                        theme.primary.opacity(0.85)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                            .shadow(color: theme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
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

// MARK: - Blurred Intangibles View (Looksmax/Umax-inspired locked preview)
struct BlurredIntangiblesView: View {
    @Environment(\.theme) var theme
    let data: PremiumIntangibles

    // Simulated live counter (in production, fetch from analytics)
    @State private var playersRevealed = Int.random(in: 2400...2900)

    var body: some View {
        ZStack {
            // Background content layer (shows actual data - will be heavily blurred)
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                LockedMetricRow(
                    emoji: "🏒",
                    label: "Nickname",
                    value: "\"\(data.lockerRoomNickname)\""
                )

                LockedMetricRow(
                    emoji: "⭐",
                    label: "Pro Comp",
                    value: data.proComparison
                )

                LockedMetricRow(
                    emoji: "💪",
                    label: "Confidence",
                    value: "\(data.confidenceScore)/100"
                )

                LockedMetricRow(
                    emoji: "✨",
                    label: "Hockey Flow",
                    value: "\(data.flowScore)/100"
                )

                LockedMetricRow(
                    emoji: "🥊",
                    label: "Toughness",
                    value: "\(data.toughnessScore)/100"
                )

                LockedMetricRow(
                    emoji: "😤",
                    label: "Intimidation",
                    value: "\(data.intimidationScore)/100"
                )
            }
            .blur(radius: 10)  // Optimal blur - visible shapes but illegible text
            .opacity(0.6)      // Higher opacity to show more content hints

            // Progressive gradient overlay (Looksmax pattern)
            VStack(spacing: 0) {
                Spacer()

                // Progressive gradient fade (balanced - show blur at top, solid at bottom)
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.3),
                        Color.black.opacity(0.7),
                        Color.black.opacity(0.9)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 140)

                // Lock message over gradient
                VStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(theme.primary)

                    Text("6 Hidden Strengths")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(theme.text)

                    Text("Elite-level insights locked")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(theme.textSecondary.opacity(0.8))
                }
                .padding(.bottom, theme.spacing.lg)
            }
        }
        .frame(height: 260)  // Slightly taller for better gradient
        .padding(theme.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    theme.primary.opacity(0.3),
                                    theme.primary.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
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

