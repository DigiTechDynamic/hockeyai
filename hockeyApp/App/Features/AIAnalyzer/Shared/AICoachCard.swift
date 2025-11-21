import SwiftUI

// MARK: - AI Coach Card
/// The main card that launches the AI Coach Flow (2-angle analysis)
struct AICoachCard: View {
    @Environment(\.theme) var theme
    let onTap: () -> Void
    @StateObject private var monetization = MonetizationManager.shared
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Original background with gradient overlay
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.4),
                                Color.black.opacity(0.2)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadius)
                            .fill(theme.surface)
                    )

                // Theme gradient border
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                theme.primary.opacity(0.6),
                                theme.accent.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )

                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("AI")
                                    .font(.system(size: 24, weight: .black))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [
                                                theme.primary,
                                                theme.primary.opacity(0.8)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: theme.primary.opacity(0.4), radius: 0, x: 0, y: 0)
                                    .shadow(color: theme.primary.opacity(0.3), radius: 4, x: 0, y: 0)

                                Text("Shot Coach")
                                    .font(.system(size: 24, weight: .black))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [
                                                Color.white,
                                                Color.white.opacity(0.9)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: Color.white.opacity(0.3), radius: 0, x: 0, y: 0)
                                    .shadow(color: Color.white.opacity(0.2), radius: 4, x: 0, y: 0)
                                if !monetization.isPremium {
                                    ProChip()
                                        .padding(.leading, 6)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Track form")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(theme.textSecondary.opacity(0.8))
                                Text("Improve technique")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(theme.textSecondary.opacity(0.8))
                                Text("Master your shot")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(theme.textSecondary.opacity(0.8))
                            }
                        }
                        
                        Spacer()
                        
                        // Icon with badge
                        ZStack {
                            Circle()
                                .fill(theme.primary.opacity(0.15))
                                .frame(width: 56, height: 56)

                            Image(systemName: "figure.hockey")
                                .font(theme.fonts.headline)
                                .foregroundColor(theme.primary)

                            // Badge
                            ZStack {
                                Circle()
                                    .fill(Color(red: 1, green: 0.2, blue: 0.2))
                                    .frame(width: 20, height: 20)

                                Text("2")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .offset(x: 20, y: -20)
                        }
                    }
                    
                    
                    // Feature badges
                    HStack(spacing: theme.spacing.sm) {
                        FeatureBadge(icon: "camera.fill", text: "2 Angles")
                        FeatureBadge(icon: "person.fill", text: "Personalized")  
                        FeatureBadge(icon: "chart.xyaxis.line", text: "AI Analysis")
                    }
                    
                    // Value blurb removed per request
                    
                    // Bottom section
                    VStack(spacing: 10) {
                        // Start Analysis button – match Home "Get My Ranking"
                        HStack(spacing: 10) {
                            Text("Start Analysis")
                                .font(theme.fonts.button)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(theme.fonts.caption)
                        }
                        .foregroundColor(theme.primary)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(theme.primary.opacity(0.10))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(theme.primary, lineWidth: 1.2)
                        )
                        .shadow(color: theme.primary.opacity(0.25), radius: 6, x: 0, y: 4)
                        
                        // Status indicator
                        HStack {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                    .overlay(
                                        Circle()
                                            .fill(Color.green.opacity(0.4))
                                            .frame(width: 14, height: 14)
                                            .blur(radius: 3)
                                    )
                                
                                Text("READY")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color.green)
                                    .tracking(0.5)
                            }
                            
                            Spacer()
                        }
                    }
                }
                .padding(20)
            }
            .shadow(color: theme.primary.opacity(0.1), radius: 8, x: 0, y: 2)
            .shadow(color: theme.accent.opacity(0.05), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Feature Badge Component
private struct FeatureBadge: View {
    @Environment(\.theme) var theme
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(theme.fonts.caption)
            Text(text)
                .font(theme.fonts.caption)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundColor(theme.textSecondary.opacity(0.7))
    }
}


// MARK: - AI Coach Featured Card (Shot Rater Style)
/// Alternative card design matching the Shot Rater aesthetic from Home screen
/// Image on right, text on left, PRO badge, glassmorphic background
struct AICoachFeaturedCard_ShotRaterStyle: View {
    @Environment(\.theme) var theme
    @StateObject private var monetization = MonetizationManager.shared
    @State private var isPressed = false

    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row like Home Shot Rater
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .shadow(color: .green, radius: 4)

                Text("AI SHOT COACH")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.textSecondary.opacity(0.95))
                    .tracking(1.2)

                Spacer()

                if !monetization.isPremium {
                    ProChip()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)

            // Split layout: text left, image right
            HStack(spacing: 0) {
                // Left: Text
                VStack(alignment: .leading, spacing: 8) {
                    Text("Master Your Shot Mechanics")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.95)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.white.opacity(0.3), radius: 0)
                        .shadow(color: Color.white.opacity(0.2), radius: 4)
                        .shadow(color: theme.primary.opacity(0.3), radius: 8, x: 0, y: 2)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 9, weight: .bold))
                            Text("2K+ analyzed")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(theme.primary)

                        Text("Dual-angle analysis with personalized coaching")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right: Image with border
                ZStack {
                    GeometryReader { proxy in
                        Image("Shoting_Side_Angle")
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipped()
                    }

                    LinearGradient(
                        colors: [theme.surface.opacity(0.4), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
                .frame(width: 170)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [theme.primary.opacity(0.6), theme.primary.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: theme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .frame(height: 190)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            // CTA like Home button
            Button(action: onTap) {
                HStack {
                    Text("Start Analysis")
                        .font(.system(size: 19, weight: .bold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(theme.primary)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(theme.primary.opacity(0.10))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(theme.primary, lineWidth: 1.2)
                )
                .shadow(color: theme.primary.opacity(0.25), radius: 6, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            // Match Stick Analysis card background
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.surface.opacity(0.9),
                                theme.background.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            theme.primary.opacity(0.6),
                            theme.accent.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: theme.primary.opacity(0.2), radius: 12, x: 0, y: 4)
    }
}

// MARK: - AI Coach Feature Row Component
private struct AICoachFeatureRow: View {
    @Environment(\.theme) var theme
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(theme.primary)
                .frame(width: 4, height: 4)
            Text(text)
        }
    }
}

// MARK: - Preview
#Preview {
    AICoachCard(onTap: {
        print("AI Coach Card tapped")
    })
    .padding()
    .background(Color.black)
}
