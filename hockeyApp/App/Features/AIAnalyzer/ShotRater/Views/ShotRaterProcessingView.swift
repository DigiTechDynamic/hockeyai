import SwiftUI
import UIKit

/// Modern analysis view for Shot Rater with athletic styling and smart progress
struct ShotRaterProcessingView: View {
    @Environment(\.theme) var theme
    let shotType: ShotType
    var onBackground: (() -> Void)? = nil
    // Simple time-based progress (smart estimator removed)

    // State for animations
    @State private var pulseAnimation = false
    @State private var progressValue: CGFloat = 0
    @State private var currentPhase = "PREPARING ANALYSIS"
    @State private var phaseDetail = "Loading your shot..."
    @State private var showPercentage = false
    @State private var percentageValue = 0

    // Network warnings removed; treat all networks the same

    // Haptic feedback
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)
    @State private var hapticTimer: Timer?

    // Shot Rater specific phases with realistic timing
    private let phases: [(title: String, detail: String, duration: Double, progress: Double)] = [
        ("PREPARING ANALYSIS", "Loading your shot...", 2.0, 0.05),
        ("DETECTING SHOT", "Finding puck and stick...", 3.0, 0.15),
        ("ANALYZING FORM", "Evaluating technique...", 5.0, 0.30),
        ("MEASURING POWER", "Calculating shot metrics...", 6.0, 0.50),
        ("RATING ACCURACY", "Assessing precision...", 5.0, 0.70),
        ("COMPUTING SCORE", "Generating final rating...", 6.0, 0.90),
        ("FINALIZING", "Preparing results...", 3.0, 1.0)
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Main content
            VStack(spacing: theme.spacing.xxl) {
                // Icon with Shot Rater specific styling
                ZStack {
                    // Outer glow layer
                    Circle()
                        .fill(theme.primary) // Use primary (green) like AI Coach
                        .frame(width: 120, height: 120)
                        .blur(radius: 35)
                        .opacity(pulseAnimation ? 0.5 : 0.3)
                        .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseAnimation)

                    // Mid glow layer
                    Circle()
                        .fill(theme.primary.opacity(0.4))
                        .frame(width: 100, height: 100)
                        .blur(radius: 20)
                        .scaleEffect(pulseAnimation ? 1.15 : 0.95)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)

                    // Outer pulsing ring
                    Circle()
                        .stroke(theme.primary.opacity(0.3), lineWidth: 2)
                        .frame(width: 110, height: 110)
                        .scaleEffect(pulseAnimation ? 1.25 : 1.0)
                        .opacity(pulseAnimation ? 0 : 0.6)
                        .animation(.easeOut(duration: 2.0).repeatForever(autoreverses: false), value: pulseAnimation)

                    // Inner circle background
                    Circle()
                        .stroke(theme.divider.opacity(0.3), lineWidth: 3)
                        .frame(width: 90, height: 90)

                    // Progress circle
                    Circle()
                        .trim(from: 0, to: progressValue)
                        .stroke(
                            LinearGradient(
                                colors: [theme.primary, theme.primary.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: progressValue)

                    // Center icon - target/bullseye for Shot Rater
                    Image(systemName: "target")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(theme.primary)
                        .shadow(color: theme.primary.opacity(0.8), radius: 4)
                        .shadow(color: theme.primary.opacity(0.5), radius: 10)
                        .shadow(color: theme.primary.opacity(0.3), radius: 20)
                        .scaleEffect(pulseAnimation ? 1.05 : 0.95)
                        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulseAnimation)
                }
                .frame(height: 120)

                // Title and phase with athletic styling
                VStack(spacing: theme.spacing.md) {
                    // Main title with gradient
                    Text("RATING YOUR SHOT")
                        .font(.system(size: 30, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color.white.opacity(0.95)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.white.opacity(0.5), radius: 0, x: 0, y: 0)
                        .shadow(color: Color.white.opacity(0.3), radius: 4, x: 0, y: 0)
                        .shadow(color: theme.primary.opacity(0.4), radius: 10, x: 0, y: 2)
                        .tracking(3)

                    // Shot type badge
                    Text(shotType.displayName.uppercased())
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(theme.primary)
                        .padding(.horizontal, theme.spacing.md)
                        .padding(.vertical, theme.spacing.xs)
                        .background(
                            Capsule()
                                .stroke(theme.primary.opacity(0.5), lineWidth: 1)
                                .background(Capsule().fill(theme.primary.opacity(0.1)))
                        )

                    // Current phase
                    VStack(spacing: theme.spacing.xs) {
                        Text(currentPhase)
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(theme.textSecondary)
                            .tracking(2)
                            .animation(.easeInOut(duration: 0.4), value: currentPhase)

                        Text(phaseDetail)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.textSecondary.opacity(0.6))
                            .animation(.easeInOut(duration: 0.4), value: phaseDetail)
                    }
                }

                // Star rating preview (animated) - unique to Shot Rater
                ShotRaterStarsIndicator(theme: theme)
                    .padding(.top, theme.spacing.sm)
            }

            Spacer()

            // Network warnings removed

            // Percentage display at bottom
            if showPercentage {
                Text("\(percentageValue)%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.textSecondary.opacity(0.4))
                    .animation(.easeIn(duration: 0.3), value: percentageValue)
            }

            Spacer().frame(height: 80)

            if let onBackground {
                AppButton(
                    title: "Continue in Background",
                    action: { onBackground() },
                    style: .primaryNeon,
                    size: .large,
                    icon: nil,
                    isLoading: false,
                    isDisabled: false,
                    fullWidth: true
                )
                .padding(.horizontal, theme.spacing.lg)
                .padding(.bottom, theme.spacing.xl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
        .onAppear {
            // Use simple linear progress
            startProcessingAnimation()
        }
        .onDisappear {
            stopHaptics()
        }
        .trackScreen("shot_rater_processing")
    }

    // MARK: - Helper Methods

    private func ratingGradientColors() -> [Color] {
        // Use same gradient as AI Coach for consistency
        let progress = progressValue
        if progress < 0.3 {
            return [.green, .green.opacity(0.8)]
        } else if progress < 0.6 {
            return [.green, .yellow.opacity(0.8)]
        } else if progress < 0.85 {
            return [.yellow, .orange.opacity(0.8)]
        } else {
            return [.orange, .red.opacity(0.8)]
        }
    }

    private func getEstimatedScore() -> String {
        // Show estimated score range based on progress
        let progress = progressValue
        if progress < 0.3 {
            return "Calculating..."
        } else if progress < 0.6 {
            return "70-80"
        } else if progress < 0.9 {
            return "80-90"
        } else {
            return "85+"
        }
    }

    private func startProcessingAnimation() {
        // Start pulse animation
        withAnimation {
            pulseAnimation = true
        }

        // Show percentage after initial delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showPercentage = true
            }
        }

        // Start haptic feedback
        impactGenerator.prepare()
        startHapticPulse()

        // Animate through phases with realistic timing
        animatePhases()

        // Animate percentage counter
        animatePercentage()
    }

    private func animatePhases() {
        var accumulatedTime: Double = 0

        for (index, phase) in phases.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + accumulatedTime) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    currentPhase = phase.title
                    phaseDetail = phase.detail
                }

                // Animate progress to this phase's target
                withAnimation(.linear(duration: phase.duration)) {
                    progressValue = phase.progress
                }
            }
            accumulatedTime += phase.duration
        }
    }

    private func animatePercentage() {
        // Total duration is 30 seconds for Shot Rater (faster than AI Coach)
        let totalDuration: Double = 30
        let steps = 100
        let stepDuration = totalDuration / Double(steps)

        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + (stepDuration * Double(step))) {
                withAnimation(.linear(duration: 0.1)) {
                    // Non-linear progression
                    let normalizedProgress = Double(step) / Double(steps)
                    let easedProgress = easeInOutProgress(normalizedProgress)
                    percentageValue = Int(easedProgress * 100)
                }
            }
        }
    }

    private func easeInOutProgress(_ t: Double) -> Double {
        // Custom easing function for realistic progress
        if t < 0.5 {
            return 2 * t * t
        } else {
            return -1 + (4 - 2 * t) * t
        }
    }

    private func startHapticPulse() {
        // Gentle haptic pulse every 2.5 seconds during processing
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            impactGenerator.impactOccurred(intensity: 0.4)
        }
    }

    private func stopHaptics() {
        hapticTimer?.invalidate()
        hapticTimer = nil
    }

    // MARK: - Smart Animation with Estimator

    // Simple linear progress replacement for previous smart estimator
    private func startSmartAnimation() {
        // Start pulse animation
        withAnimation {
            pulseAnimation = true
        }

        // Start haptic feedback
        impactGenerator.prepare()
        startHapticPulse()

        // Drive progress linearly over time
        startProcessingAnimation()
    }

    private func updatePhaseFromProgress(_ progress: Double) {
        let newPhase: (title: String, detail: String)

        switch progress {
        case 0..<0.05:
            newPhase = ("PREPARING ANALYSIS", "Loading your shot...")
        case 0.05..<0.15:
            newPhase = ("DETECTING SHOT", "Finding puck and stick...")
        case 0.15..<0.30:
            newPhase = ("ANALYZING FORM", "Evaluating technique...")
        case 0.30..<0.50:
            newPhase = ("MEASURING POWER", "Calculating shot metrics...")
        case 0.50..<0.70:
            newPhase = ("RATING ACCURACY", "Assessing precision...")
        case 0.70..<0.90:
            newPhase = ("COMPUTING SCORE", "Generating final rating...")
        default:
            newPhase = ("FINALIZING", "Preparing results...")
        }

        if currentPhase != newPhase.title {
            withAnimation(.easeInOut(duration: 0.4)) {
                currentPhase = newPhase.title
                phaseDetail = newPhase.detail
            }
        }
    }

    // Network quality checks removed
}

// MARK: - Animated Stars Component (unique to Shot Rater)
struct ShotRaterStarsIndicator: View {
    let theme: any AppTheme
    @State private var activeIndex = 0
    @State private var starScale: [CGFloat] = [1.0, 1.0, 1.0, 1.0, 1.0]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<5) { index in
                ZStack {
                    // Glow effect for active star - using primary (green) theme
                    if index <= activeIndex {
                        Image(systemName: "star.fill")
                            .font(.system(size: 20))
                            .foregroundColor(theme.primary) // Green theme
                            .blur(radius: 8)
                            .opacity(0.6)
                    }

                    // Main star
                    Image(systemName: index <= activeIndex ? "star.fill" : "star")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(index <= activeIndex ? theme.primary : theme.divider.opacity(0.3)) // Green when filled
                        .scaleEffect(starScale[index])
                        .shadow(color: index <= activeIndex ? theme.primary.opacity(0.6) : .clear, radius: 3)
                }
                .animation(.easeInOut(duration: 0.3), value: activeIndex)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: starScale[index])
            }
        }
        .onAppear {
            animateStars()
        }
    }

    private func animateStars() {
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
            withAnimation {
                activeIndex = (activeIndex + 1) % 5

                // Create wave effect
                for i in 0..<5 {
                    if i == activeIndex {
                        starScale[i] = 1.3
                    } else {
                        starScale[i] = 1.0
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct ShotRaterProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        ShotRaterProcessingView(
            shotType: .wristShot
        )
        .preferredColorScheme(.dark)
    }
}
