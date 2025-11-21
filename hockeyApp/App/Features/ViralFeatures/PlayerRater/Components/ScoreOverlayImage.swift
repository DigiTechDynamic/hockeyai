import SwiftUI
import UIKit

// MARK: - Score Overlay Image Component
/// Displays player photo with score overlaid at bottom
/// Simple centered layout without face detection
struct ScoreOverlayImage: View {
    @Environment(\.theme) var theme
    let image: UIImage
    let score: Int
    let imageScale: CGFloat

    @State private var showScore = false

    var body: some View {
        GeometryReader { geometry in
            let containerHeight = max(min(UIScreen.main.bounds.height * 0.40, 360), 200)

            ZStack(alignment: .bottom) {
                // Background blur layer
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: containerHeight)
                    .clipped()
                    .blur(radius: 18)
                    .saturation(0.9)
                    .opacity(0.85)

                // Main image (fit) - centered
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: containerHeight)
                    .scaleEffect(imageScale)
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 3)

                // Bottom gradient overlay for readability
                LinearGradient(
                    colors: [
                        .clear,
                        .black.opacity(0.3),
                        .black.opacity(0.6),
                        .black.opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: containerHeight * 0.4)

                // Score overlay at bottom
                VStack(spacing: 8) {
                    Text("\(score)")
                        .font(.system(size: 72, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: theme.primary.opacity(0.6), radius: 20, x: 0, y: 0)
                        .shadow(color: theme.primary.opacity(0.4), radius: 30, x: 0, y: 5)
                        .shadow(color: .black.opacity(0.5), radius: 10, y: 4)
                        .scaleEffect(showScore ? 1.0 : 0.8)
                        .opacity(showScore ? 1.0 : 0)
                }
                .padding(.bottom, 24)
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
        .frame(height: UIScreen.main.bounds.height * 0.40)
        .onAppear {
            // Animate score in after slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showScore = true
                }
            }
        }
    }
}

// MARK: - Score Card Overlay (Clean Version)
/// Score in a frosted glass card at bottom - simple centered layout
struct ScoreCardOverlayImage: View {
    @Environment(\.theme) var theme
    let image: UIImage
    let score: Int
    let archetype: String
    let imageScale: CGFloat
    var isOnboarding: Bool = false

    @State private var showCard = false

    // Helper for consistent container height calculation
    private var containerHeight: CGFloat {
        max(min(UIScreen.main.bounds.height * 0.40, 360), 200)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background blur layer
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: containerHeight)
                    .clipped()
                    .blur(radius: 18)
                    .saturation(0.9)
                    .opacity(0.85)

                // Main image (fit) - centered
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: containerHeight)
                    .scaleEffect(imageScale)
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 3)

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
                    if isOnboarding {
                        // Onboarding: Just show "VALIDATED"
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(theme.primary)
                                .shadow(color: theme.primary.opacity(0.6), radius: 12)

                            Text("VALIDATED")
                                .font(.system(size: 28, weight: .black))
                                .foregroundColor(.white)
                                .tracking(2.0)
                                .shadow(color: theme.primary.opacity(0.4), radius: 8)
                        }

                        Spacer()
                    } else {
                        // Normal STY Check: Show score + tier
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
                        Text(archetype.uppercased())
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.white)
                            .tracking(1.5)

                        Spacer()
                    }
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
                // Full-perimeter gradient border for maximum shareability
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [theme.primary.opacity(0.9), theme.accent.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 4  // Increased for premium card look
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
}

// MARK: - Score Badge Overlay (Bottom Corner)
/// Clean badge in bottom-right corner
struct ScoreBadgeOverlayImage: View {
    @Environment(\.theme) var theme
    let image: UIImage
    let score: Int
    let imageScale: CGFloat

    @State private var showBadge = false

    var body: some View {
        GeometryReader { geometry in
            let containerHeight = max(min(UIScreen.main.bounds.height * 0.40, 360), 200)

            ZStack(alignment: .bottomTrailing) {
                // Background blur layer
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: containerHeight)
                    .clipped()
                    .blur(radius: 18)
                    .saturation(0.9)
                    .opacity(0.85)

                // Main image (fit) - centered
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: containerHeight)
                    .scaleEffect(imageScale)
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 3)

                // Score badge (bottom-right)
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(theme.primary)
                        .frame(width: 90, height: 90)
                        .blur(radius: 20)
                        .opacity(0.6)

                    // Badge background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.8),
                                    Color.black.opacity(0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    // Border
                    Circle()
                        .strokeBorder(theme.primary, lineWidth: 3)
                        .frame(width: 80, height: 80)

                    // Score text
                    Text("\(score)")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: theme.primary.opacity(0.8), radius: 8)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
                .scaleEffect(showBadge ? 1.0 : 0.5)
                .opacity(showBadge ? 1.0 : 0)
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
        .frame(height: UIScreen.main.bounds.height * 0.40)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    showBadge = true
                }
            }
        }
    }
}

// MARK: - Shared Shapes

/// Bottom-only rounded corners shape
struct BottomRoundedCorners: Shape {
    var radius: CGFloat = 20

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.bottomLeft, .bottomRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

/// Top-rounded corners shape (for card image)
struct TopRoundedCorners: Shape {
    var radius: CGFloat = 20

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

/// Fully rounded corners shape
struct AllRoundedCorners: Shape {
    var radius: CGFloat = 20

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            cornerRadius: radius
        )
        return Path(path.cgPath)
    }
}
