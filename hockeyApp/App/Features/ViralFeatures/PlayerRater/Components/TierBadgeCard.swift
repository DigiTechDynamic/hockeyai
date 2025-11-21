import SwiftUI

// MARK: - Tier Badge Card (Vertical Validator + Ranking Bar)
struct TierBadgeCard: View {
    @Environment(\.theme) var theme
    let score: Int
    let archetype: String
    let archetypeEmoji: String
    let showContent: Bool
    let isCompact: Bool

    var percentile: Int {
        calculatePercentile(score: score)
    }

    // Use theme-driven primary color for all visuals (no hardcoded palettes)
    var tierColor: Color { theme.primary }

    var body: some View {
        VStack(spacing: isCompact ? 10 : 16) {
            // Modern Tier Label with enhanced accent line
            HStack(spacing: 10) {
                // Enhanced accent line (thicker, taller)
                Rectangle()
                    .fill(tierColor)
                    .frame(width: 3, height: isCompact ? 18 : 28)

                // Tier info (inline)
                HStack(spacing: 8) {
                    Text(archetype.uppercased())
                        .font(.system(size: isCompact ? 14 : 18, weight: .heavy))
                        .foregroundColor(theme.text)
                        .tracking(2.0)

                    Text("•")
                        .font(.system(size: isCompact ? 12 : 14, weight: .bold))
                        .foregroundColor(theme.textSecondary.opacity(0.5))

                    Text("Top \(percentile)%")
                        .font(.system(size: isCompact ? 13 : 15, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, theme.spacing.lg)

            // Modern Ranking Bar
            RankingBarView(score: score, tierColor: tierColor, isCompact: isCompact)
                .padding(.horizontal, theme.spacing.lg)
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 10)
    }

    // MARK: - Percentile Calculation (More Confidence-Boosting)
    private func calculatePercentile(score: Int) -> Int {
        switch score {
        case 97...100: return 1    // Top 1% - Elite tier
        case 95...96:  return 3    // Top 3%
        case 93...94:  return 5    // Top 5%
        case 90...92:  return 8    // Top 8% - Elite tier (boosted from 10%)
        case 87...89:  return 12   // Top 12% - Premium tier (boosted from 15%)
        case 84...86:  return 15   // Top 15% (boosted from 20%)
        case 81...83:  return 20   // Top 20% (boosted from 25%)
        case 78...80:  return 25   // Top 25% (boosted from 30%)
        case 75...77:  return 30   // Top 30% (boosted from 35%)
        case 72...74:  return 40   // Top 40% (boosted from 45%)
        case 69...71:  return 50   // Top 50% - Median
        case 66...68:  return 60   // Above 40% of users
        case 63...65:  return 65   // Above 35% of users
        case 60...62:  return 70   // Developing
        case 55...59:  return 80   // Below average
        default:       return 95   // Bottom tier (for non-hockey items)
        }
    }
}

// MARK: - Ranking Bar (Neon Glass, Animated)
struct RankingBarView: View {
    @Environment(\.theme) var theme
    let score: Int
    let tierColor: Color
    let isCompact: Bool

    @State private var animatedProgress: CGFloat = 0

    private var progress: CGFloat {
        min(max(CGFloat(score) / 100.0, 0), 1)
    }

    var body: some View {
        VStack(spacing: isCompact ? 6 : 10) {
            GeometryReader { geometry in
                let width = geometry.size.width
                let knobDiameter: CGFloat = isCompact ? 18 : 36  // Compact vs regular
                let trackHeight: CGFloat = isCompact ? 7 : 14    // Compact vs regular
                let knobX = animatedProgress * max(0, width - knobDiameter) + knobDiameter/2

                VStack(spacing: 0) {
                    ZStack(alignment: .leading) {
                        // Glass track with enhanced depth
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        theme.text.opacity(0.12),
                                        theme.text.opacity(0.08),
                                        theme.text.opacity(0.06),
                                        theme.text.opacity(0.04)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(theme.background.opacity(0.30))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(theme.text.opacity(0.15), lineWidth: 1)
                            )
                            .frame(height: trackHeight)

                        // Filled progress with enhanced 4-stop gradient
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        tierColor.opacity(0.95),
                                        tierColor.opacity(0.90),
                                        tierColor,
                                        tierColor.opacity(0.85)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(knobDiameter/2, knobX), height: trackHeight)
                            .shadow(color: tierColor.opacity(0.40), radius: 10, x: 0, y: 0)
                            .mask(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .frame(height: trackHeight)
                            )

                        // Premium knob with triple-layer glow and highlight
                        ZStack {
                            // Layer 1: Outer glow (largest, most subtle)
                            Circle()
                                .fill(tierColor.opacity(0.15))
                                .blur(radius: isCompact ? 12 : 22)
                                .frame(width: knobDiameter * (isCompact ? 1.5 : 1.8), height: knobDiameter * (isCompact ? 1.5 : 1.8))

                            // Layer 2: Middle glow
                            Circle()
                                .fill(tierColor.opacity(0.30))
                                .blur(radius: isCompact ? 8 : 12)
                                .frame(width: knobDiameter * (isCompact ? 1.25 : 1.4), height: knobDiameter * (isCompact ? 1.25 : 1.4))

                            // Layer 3: Inner glow (tightest, most intense)
                            Circle()
                                .fill(tierColor.opacity(0.50))
                                .blur(radius: isCompact ? 4 : 6)
                                .frame(width: knobDiameter * (isCompact ? 1.05 : 1.1), height: knobDiameter * (isCompact ? 1.05 : 1.1))

                            // Main knob with enhanced gradient
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            tierColor.opacity(0.95),
                                            tierColor,
                                            tierColor.opacity(0.90),
                                            tierColor.opacity(0.85)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    // Highlight overlay for depth
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.25),
                                                    Color.white.opacity(0.10),
                                                    Color.clear
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .center
                                            )
                                        )
                                )
                                .overlay(
                                    Circle().stroke(theme.text.opacity(0.9), lineWidth: isCompact ? 1.5 : 2)
                                )
                                .shadow(color: tierColor.opacity(0.70), radius: isCompact ? 8 : 12)
                                .frame(width: knobDiameter, height: knobDiameter)
                        }
                        .offset(x: knobX - knobDiameter/2, y: 0)
                    }
                    .frame(height: knobDiameter)
                }
            }
            .frame(height: isCompact ? (22 + 6) : 50)  // Compact height matches smaller knob

            // Enhanced tier markers
            HStack(spacing: 0) {
                tierMarker("50"); Spacer()
                tierMarker("70"); Spacer()
                tierMarker("80"); Spacer()
                tierMarker("90"); Spacer()
                tierMarker("100")
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: score) { _ in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedProgress = progress
            }
        }
    }

    private func tierMarker(_ label: String) -> some View {
        Text(label)
            .font(.system(size: isCompact ? 9.5 : 11, weight: .medium))
            .foregroundColor(theme.textSecondary.opacity(0.50))
            .monospacedDigit()
    }
}
