import SwiftUI
import UIKit

struct AICoachFlowProcessingView: View {
    @Environment(\.theme) var theme
    let processingMessage: String
    // Simple time-based progress only (smart estimator removed)

    // State for animations
    @State private var pulseAnimation = false
    @State private var progressValue: CGFloat = 0
    @State private var currentPhase = "INITIALIZING ANALYSIS"
    @State private var phaseDetail = "Preparing video frames..."
    @State private var phaseIndex = 0
    @State private var showPercentage = false
    @State private var percentageValue = 0

    // Network warnings removed

    // Haptic feedback
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)
    @State private var hapticTimer: Timer?

    // Processing phases with realistic timing
    private let phases: [(title: String, detail: String, duration: Double, progress: Double)] = [
        ("INITIALIZING ANALYSIS", "Preparing video frames...", 3.0, 0.08),
        ("EXTRACTING FRAMES", "Processing video angles...", 5.0, 0.20),
        ("DETECTING MOTION", "Analyzing body mechanics...", 6.0, 0.35),
        ("EVALUATING TECHNIQUE", "Checking shot fundamentals...", 8.0, 0.55),
        ("PROCESSING ANGLES", "Comparing dual perspectives...", 7.0, 0.75),
        ("GENERATING INSIGHTS", "Creating personalized feedback...", 9.0, 0.95),
        ("FINALIZING REPORT", "Completing analysis...", 2.0, 1.0)
    ]

    var body: some View {
        ZStack {
            // Background
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Main content
                VStack(spacing: theme.spacing.xxl) {
                    // Icon with glow effects like SharedValidationView
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

                        // Center icon with multiple shadows
                        Image(systemName: "waveform.badge.magnifyingglass")
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
                        Text("ANALYZING SHOT")
                            .font(.system(size: 32, weight: .black))
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

                        // Current phase
                        VStack(spacing: theme.spacing.xs) {
                            Text(currentPhase)
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundColor(theme.primary)
                                .tracking(2)
                                .animation(.easeInOut(duration: 0.4), value: currentPhase)

                            Text(phaseDetail)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(theme.textSecondary.opacity(0.6))
                                .animation(.easeInOut(duration: 0.4), value: phaseDetail)
                        }
                    }

                    // Animated dots indicator
                    AnalysisDotsIndicator()
                        .padding(.top, theme.spacing.sm)
                }

                Spacer()

                // Network warning UI removed

                // Percentage display at bottom
                if showPercentage {
                    Text("\(percentageValue)%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(theme.textSecondary.opacity(0.4))
                        .animation(.easeIn(duration: 0.3), value: percentageValue)
                }

                Spacer().frame(height: 40)
            }
        }
        .onAppear {
            // Network checks removed
            // Always use simple processing animation
            startProcessingAnimation()
        }
        .onDisappear {
            stopHaptics()
        }
    }

    // Network checks removed

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
                    phaseIndex = index
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
        // Total duration is 40 seconds
        let totalDuration: Double = 40
        let steps = 100
        let stepDuration = totalDuration / Double(steps)

        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + (stepDuration * Double(step))) {
                withAnimation(.linear(duration: 0.1)) {
                    // Non-linear progression - slower at start and end
                    let normalizedProgress = Double(step) / Double(steps)
                    let easedProgress = easeInOutProgress(normalizedProgress)
                    percentageValue = Int(easedProgress * 100)
                }
            }
        }
    }

    private func easeInOutProgress(_ t: Double) -> Double {
        // Custom easing function for more realistic progress
        if t < 0.5 {
            return 2 * t * t
        } else {
            return -1 + (4 - 2 * t) * t
        }
    }

    private func startHapticPulse() {
        // Gentle haptic pulse every 2 seconds during processing
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            impactGenerator.impactOccurred(intensity: 0.3)
        }
    }

    private func stopHaptics() {
        hapticTimer?.invalidate()
        hapticTimer = nil
    }

    // Simple linear progress only
    private func startSmartAnimation() {
        // Start pulse animation
        withAnimation {
            pulseAnimation = true
        }

        // Start haptic feedback
        impactGenerator.prepare()
        startHapticPulse()

        startProcessingAnimation()
    }

    private func updatePhaseFromProgress(_ progress: Double) {
        let newPhase: (title: String, detail: String)

        switch progress {
        case 0..<0.08:
            newPhase = ("INITIALIZING ANALYSIS", "Preparing video frames...")
        case 0.08..<0.20:
            newPhase = ("EXTRACTING FRAMES", "Processing video angles...")
        case 0.20..<0.35:
            newPhase = ("DETECTING MOTION", "Analyzing body mechanics...")
        case 0.35..<0.55:
            newPhase = ("EVALUATING TECHNIQUE", "Checking shot fundamentals...")
        case 0.55..<0.75:
            newPhase = ("PROCESSING ANGLES", "Comparing dual perspectives...")
        case 0.75..<0.95:
            newPhase = ("GENERATING INSIGHTS", "Creating personalized feedback...")
        default:
            newPhase = ("FINALIZING REPORT", "Completing analysis...")
        }

        if currentPhase != newPhase.title {
            withAnimation(.easeInOut(duration: 0.4)) {
                currentPhase = newPhase.title
                phaseDetail = newPhase.detail
            }
        }
    }
}

// MARK: - Animated Dots Component
struct AnalysisDotsIndicator: View {
    @Environment(\.theme) var theme
    @State private var activeIndex = 0
    @State private var dotScale: [CGFloat] = [1.0, 1.0, 1.0, 1.0, 1.0]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<5) { index in
                ZStack {
                    // Glow effect for active dot
                    if activeIndex == index {
                        Circle()
                            .fill(theme.primary)
                            .frame(width: 10, height: 10)
                            .blur(radius: 5)
                            .opacity(0.6)
                    }

                    // Main dot
                    Circle()
                        .fill(activeIndex == index ? theme.primary : theme.divider.opacity(0.3))
                        .frame(width: 6, height: 6)
                        .scaleEffect(dotScale[index])
                        .shadow(color: activeIndex == index ? theme.primary.opacity(0.6) : .clear, radius: 3)
                }
                .animation(.easeInOut(duration: 0.3), value: activeIndex)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: dotScale[index])
            }
        }
        .onAppear {
            animateDots()
        }
    }

    private func animateDots() {
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { timer in
            withAnimation {
                activeIndex = (activeIndex + 1) % 5

                // Create wave effect
                for i in 0..<5 {
                    if i == activeIndex {
                        dotScale[i] = 1.4
                    } else {
                        dotScale[i] = 1.0
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct AICoachFlowProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        AICoachFlowProcessingView(processingMessage: "Analyzing your shot...")
            .preferredColorScheme(.dark)
    }
}
