import SwiftUI

// MARK: - Skill Check Hero View
/// Hook screen that shows value before asking for video
/// Key insight: Show what users GET before asking them to DO anything
struct SkillCheckHeroView: View {
    @Environment(\.theme) var theme
    let onStart: () -> Void

    @State private var showContent = false
    @State private var pulseButton = false
    @State private var exampleScore = 0
    @State private var scoreTimer: Timer?

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    theme.background,
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero section with example score card
                    heroSection

                    // Value proposition
                    valueSection
                        .padding(.top, 24)

                    // CTA Button
                    ctaButton
                        .padding(.top, 32)
                        .padding(.horizontal, 24)

                    // Social proof
                    socialProof
                        .padding(.top, 20)

                    // Bottom padding
                    Color.clear.frame(height: 40)
                }
            }
        }
        .onAppear {
            // Track hero viewed (Step 1)
            SkillCheckAnalytics.trackHeroViewed()

            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
            startExampleScoreAnimation()
            startButtonPulse()
        }
        .onDisappear {
            scoreTimer?.invalidate()
        }
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 16) {
            // Example score preview card
            ZStack {
                // Background glow
                Circle()
                    .fill(theme.primary.opacity(0.15))
                    .frame(width: 200, height: 200)
                    .blur(radius: 60)

                // Score card preview
                VStack(spacing: 8) {
                    // Score display
                    Text("\(exampleScore)")
                        .font(.system(size: 72, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: theme.primary.opacity(0.6), radius: 20)

                    // Tier badge
                    Text(getTierLabel(for: exampleScore))
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.black)
                        .tracking(2)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(theme.primary)
                        )
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            theme.primary.opacity(0.8),
                                            theme.primary.opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                )
                .shadow(color: theme.primary.opacity(0.3), radius: 30, y: 10)
            }
            .scaleEffect(showContent ? 1 : 0.8)
            .opacity(showContent ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: showContent)
        }
        .padding(.top, 20)
    }

    // MARK: - Value Section
    private var valueSection: some View {
        VStack(spacing: 16) {
            Text("GET YOUR SKILL SCORE")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.white)
                .tracking(1)
                .multilineTextAlignment(.center)

            Text("Upload any hockey clip and our AI will rate your skill, style, and viral potential")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)

            // Quick benefits
            HStack(spacing: 24) {
                benefitItem(icon: "bolt.fill", text: "30 sec")
                benefitItem(icon: "sparkles", text: "AI Rated")
                benefitItem(icon: "chart.line.uptrend.xyaxis", text: "Viral Score")
            }
            .padding(.top, 8)
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.3), value: showContent)
    }

    private func benefitItem(icon: String, text: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(theme.primary)

            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(theme.textSecondary)
        }
    }

    // MARK: - CTA Button
    private var ctaButton: some View {
        Button(action: {
            HapticManager.shared.playImpact(style: .medium)
            onStart()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "video.fill")
                    .font(.system(size: 18, weight: .semibold))

                Text("Rate My Skill")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                ZStack {
                    // Base
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.primary)

                    // Pulse glow
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.primary)
                        .blur(radius: 20)
                        .opacity(pulseButton ? 0.6 : 0.3)
                        .scaleEffect(pulseButton ? 1.1 : 1.0)
                }
            )
            .shadow(color: theme.primary.opacity(0.5), radius: 20, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(showContent ? 1 : 0.9)
        .opacity(showContent ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: showContent)
    }

    // MARK: - Social Proof
    private var socialProof: some View {
        HStack(spacing: 8) {
            // Stacked avatars placeholder
            HStack(spacing: -8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.primary.opacity(0.8), theme.primary.opacity(0.4)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(theme.background, lineWidth: 2)
                        )
                }
            }

            Text("2,847 skills rated today")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.textSecondary)
        }
        .opacity(showContent ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.5), value: showContent)
    }

    // MARK: - Helpers

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

    private func startExampleScoreAnimation() {
        // Animate to a high score to show value
        let targetScore = 87
        exampleScore = 0

        scoreTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            if exampleScore < targetScore {
                exampleScore += 1
            } else {
                timer.invalidate()
            }
        }
    }

    private func startButtonPulse() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseButton = true
        }
    }
}

// MARK: - Preview
#Preview {
    SkillCheckHeroView(onStart: {})
        .preferredColorScheme(.dark)
}
