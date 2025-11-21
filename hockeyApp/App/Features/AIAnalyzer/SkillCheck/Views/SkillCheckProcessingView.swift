import SwiftUI
import UIKit

/// Processing view for Skill Check with athletic styling
struct SkillCheckProcessingView: View {
    @Environment(\.theme) var theme

    // State for animations
    @State private var pulseAnimation = false
    @State private var progressValue: CGFloat = 0
    @State private var currentPhase = "PREPARING ANALYSIS"
    @State private var phaseDetail = "Loading your video..."
    @State private var showPercentage = false
    @State private var percentageValue = 0

    // Haptic feedback
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)
    @State private var hapticTimer: Timer?

    // Skill Check specific phases
    private let phases: [(title: String, detail: String, duration: Double, progress: Double)] = [
        ("PREPARING ANALYSIS", "Loading your video...", 2.0, 0.05),
        ("DETECTING SKILL", "Identifying what you're doing...", 3.0, 0.15),
        ("ANALYZING TECHNIQUE", "Evaluating form and execution...", 5.0, 0.35),
        ("ASSESSING QUALITY", "Rating skill level...", 5.0, 0.60),
        ("FINDING HIGHLIGHTS", "Identifying strengths...", 4.0, 0.80),
        ("GENERATING TIPS", "Creating improvement suggestions...", 4.0, 0.95),
        ("FINALIZING", "Preparing results...", 2.0, 1.0)
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Main content
            VStack(spacing: theme.spacing.xxl) {
                // Icon with Skill Check specific styling
                ZStack {
                    // Outer glow layer
                    Circle()
                        .fill(theme.primary)
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

                    // Center icon - sparkles for skill analysis
                    Image(systemName: "sparkles")
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
                    Text("ANALYZING YOUR SKILL")
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

                    // Skill check badge
                    Text("AI SKILL ANALYSIS")
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
            }

            Spacer()

            // Percentage display at bottom
            if showPercentage {
                Text("\(percentageValue)%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.textSecondary.opacity(0.4))
                    .animation(.easeIn(duration: 0.3), value: percentageValue)
            }

            Spacer().frame(height: 80)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
        .onAppear {
            startProcessingAnimation()
        }
        .onDisappear {
            stopHaptics()
        }
        .trackScreen("skill_check_processing")
    }

    // MARK: - Helper Methods

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
        // Total duration is 25 seconds for Skill Check
        let totalDuration: Double = 25
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
}

// MARK: - Preview
struct SkillCheckProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        SkillCheckProcessingView()
            .preferredColorScheme(.dark)
    }
}
