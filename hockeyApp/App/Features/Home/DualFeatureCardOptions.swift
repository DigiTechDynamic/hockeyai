import SwiftUI

struct DualFeatureCard_Option4: View {
    @Environment(\.theme) var theme
    @StateObject private var monetization = MonetizationManager.shared
    @State private var isPressedLeft = false
    @State private var isPressedRight = false

    let onStyCheckTap: () -> Void
    let onShotRaterTap: () -> Void

    // Background layer extracted for type-check performance
    @ViewBuilder
    private var backgroundLayer: some View {
        ZStack {
            GeometryReader { proxy in
                Image("shotting")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .offset(y: 30) // Move image down to show player's head
                    .clipped()
            }
            LinearGradient(
                colors: [
                    Color.black.opacity(0.1),
                    Color.black.opacity(0.5),
                    Color.black.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            theme.primary.opacity(0.12)
                .blendMode(.overlay)
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            backgroundLayer

            VStack(spacing: 0) {
                titleHeader

                Spacer()

                // DUAL GLASSMORPHIC CTAs at bottom (split 50/50)
                cardsRow
            }
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            theme.primary.opacity(0.8),
                            theme.accent.opacity(0.5),
                            theme.primary.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
                .shadow(color: theme.primary.opacity(0.3), radius: 4, x: 0, y: 0)
        )
        .shadow(color: theme.primary.opacity(0.3), radius: 20, x: 0, y: 8)
        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 20)
    }

    // MARK: - Helper Views
    private var titleHeader: some View {
        VStack(spacing: 6) {
            Text("GET RATED")
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.95)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .white.opacity(0.5), radius: 0)
                .shadow(color: .white.opacity(0.3), radius: 4)
                .shadow(color: .white.opacity(0.2), radius: 8)
                .shadow(color: theme.primary.opacity(0.4), radius: 12, x: 0, y: 2)

            Text("AI-powered hockey analysis")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
        }
        .padding(.top, 16)
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private var cardsRow: some View {
        HStack(spacing: 8) {
            leftCard
            rightCard
        }
        .frame(height: 122)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    private var leftCard: some View {
        Button(action: onStyCheckTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text("STY CHECK")
                        .font(.system(size: 20, weight: .black))
                        .glowingHeaderText()
                        .tracking(0.5)
                        .textCase(.uppercase)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .layoutPriority(1)
                    Spacer(minLength: 4)
                }
                .padding(.trailing, 28)

                Text("Get your hockey style rating")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(glassCardBackground(cornerRadius: 14))
            .overlay(glassCardStroke(cornerRadius: 14))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: theme.primary.opacity(0.22), radius: 7, x: 0, y: 0)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressedLeft ? 0.96 : 1.0)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            isPressedLeft = pressing
        }, perform: {})
    }

    private var rightCard: some View {
        Button(action: onShotRaterTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text("SKILL CHECK")
                        .font(.system(size: 20, weight: .black))
                        .glowingHeaderText()
                        .tracking(0.5)
                        .textCase(.uppercase)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .layoutPriority(1)
                    Spacer(minLength: 4)
                }
                .padding(.trailing, 28)

                Text("Get AI feedback on any hockey skill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(glassCardBackground(cornerRadius: 14))
            .overlay(glassCardStroke(cornerRadius: 14))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: theme.primary.opacity(0.22), radius: 7, x: 0, y: 0)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressedRight ? 0.96 : 1.0)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            isPressedRight = pressing
        }, perform: {})
    }

    private func glassCardBackground(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
    }

    private func glassCardStroke(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        theme.primary.opacity(0.7),
                        theme.primary.opacity(0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 2
            )
    }
}
