import SwiftUI

// MARK: - Option 1: Split Card with Glowing Divider (REFINED)
// Matches the visual style from app screenshots with exact glow effects,
// PRO chip styling, and premium glassmorphic design
struct DualFeatureCard_Option1_Refined: View {
    @Environment(\.theme) var theme
    @StateObject private var monetization = MonetizationManager.shared
    @State private var isPressedTop = false
    @State private var isPressedBottom = false
    @State private var dividerGlow: CGFloat = 0.6

    let onStyCheckTap: () -> Void
    let onShotRaterTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // TOP: STY CHECK (FREE)
            Button(action: onStyCheckTap) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        // Title with glow effect (matching screenshot #4 "GET RATED" text)
                        Text("STY CHECK")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.white)
                            // Multiple shadow layers for white glow effect
                            .shadow(color: .white.opacity(0.3), radius: 0, x: 0, y: 0)
                            .shadow(color: .white.opacity(0.2), radius: 2, x: 0, y: 0)
                            .shadow(color: .white.opacity(0.15), radius: 4, x: 0, y: 0)

                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.primary)
                            Text("Rate Your Gear")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.75))
                        }
                    }

                    Spacer()

                    // FREE Badge - Bright green background, black text, high contrast
                    Text("FREE")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(theme.primary)
                        )
                        .shadow(color: theme.primary.opacity(0.5), radius: 6, x: 0, y: 2)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(isPressedTop ? theme.primary.opacity(0.05) : Color.clear)
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(isPressedTop ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressedTop)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                isPressedTop = pressing
            }, perform: {})

            // DIVIDER: Glowing neon line with gradient
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            theme.primary.opacity(0.3),
                            theme.primary,
                            theme.primary.opacity(0.3)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .shadow(color: theme.primary.opacity(dividerGlow), radius: 8, y: 0)
                .shadow(color: theme.primary.opacity(dividerGlow * 0.6), radius: 16, y: 0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        dividerGlow = 0.9
                    }
                }

            // BOTTOM: SHOT RATER (PRO)
            Button(action: onShotRaterTap) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        // Title with glow effect
                        Text("SHOT RATER")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.white)
                            // Multiple shadow layers for white glow effect
                            .shadow(color: .white.opacity(0.3), radius: 0, x: 0, y: 0)
                            .shadow(color: .white.opacity(0.2), radius: 2, x: 0, y: 0)
                            .shadow(color: .white.opacity(0.15), radius: 4, x: 0, y: 0)

                        HStack(spacing: 8) {
                            Image(systemName: "target")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.primary)
                            Text("Analyze Your Technique")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.75))
                        }
                    }

                    Spacer()

                    // PRO Chip (matching screenshot #5)
                    // Crown icon + PRO text, dark background, subtle border
                    if !monetization.isPremium {
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text("PRO")
                                .font(.system(size: 11, weight: .heavy))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.6))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(isPressedBottom ? theme.primary.opacity(0.05) : Color.clear)
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(isPressedBottom ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressedBottom)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                isPressedBottom = pressing
            }, perform: {})
        }
        .background(
            // Glassmorphic base (.ultraThinMaterial)
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    // Dark surface overlay for depth
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.surface.opacity(0.85),
                                    theme.surface.opacity(0.75)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            // Green gradient border (matching screenshots #1, #2, #3)
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            theme.primary.opacity(0.7),
                            theme.primary.opacity(0.5),
                            theme.primary.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        // Subtle green glow shadow underneath
        .shadow(color: theme.primary.opacity(0.15), radius: 16, x: 0, y: 4)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)
        .frame(height: 200)
        .padding(.horizontal, 20)
    }
}

// MARK: - Preview
#Preview {
    DualFeatureCard_Option1_Refined(
        onStyCheckTap: {},
        onShotRaterTap: {}
    )
    .preferredColorScheme(.dark)
}
