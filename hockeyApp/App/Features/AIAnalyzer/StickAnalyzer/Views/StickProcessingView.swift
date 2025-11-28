import SwiftUI

// MARK: - Stick Processing View (consistent with other features)
struct StickProcessingView: View {
    @Environment(\.theme) var theme
    let primaryMessage: String
    // Simple time-based progress only (smart estimator removed)
    let contextChips: [String]?

    // Animations and state
    @State private var pulseAnimation = false
    @State private var progressValue: CGFloat = 0
    @State private var currentPhase = "INITIALIZING"
    @State private var phaseDetail = "Preparing video frames..."
    @State private var showPercentage = false
    @State private var percentageValue = 0
    @State private var currentStep = 0
    @State private var dotScale: CGFloat = 1.0

    // Network warnings removed

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Loading puck (replaces wand icon)
            GeometryReader { geo in
                let size = min(max(geo.size.width * 0.45, 120), 160)
                ZStack {
                    Circle()
                        .fill(theme.primary)
                        .frame(width: size, height: size)
                        .blur(radius: 35)
                        .opacity(pulseAnimation ? 0.5 : 0.3)
                        .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseAnimation)

                    Circle()
                        .fill(theme.primary.opacity(0.4))
                        .frame(width: size - 20, height: size - 20)
                        .blur(radius: 20)
                        .scaleEffect(pulseAnimation ? 1.15 : 0.95)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)

                    Circle()
                        .stroke(theme.primary.opacity(0.3), lineWidth: 2)
                        .frame(width: size - 10, height: size - 10)
                        .scaleEffect(pulseAnimation ? 1.25 : 1.0)
                        .opacity(pulseAnimation ? 0 : 0.6)
                        .animation(.easeOut(duration: 2.0).repeatForever(autoreverses: false), value: pulseAnimation)

                    Circle()
                        .stroke(theme.divider.opacity(0.3), lineWidth: 3)
                        .frame(width: size - 30, height: size - 30)

                    Circle()
                        .trim(from: 0, to: progressValue)
                        .stroke(
                            LinearGradient(colors: [theme.primary, theme.primary.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: size - 30, height: size - 30)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: progressValue)

                    VStack(spacing: 4) {
                        Image(systemName: "hockey.puck")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(theme.primary)
                            .shadow(color: theme.primary.opacity(0.8), radius: 4)
                            .shadow(color: theme.primary.opacity(0.5), radius: 10)
                            .shadow(color: theme.primary.opacity(0.3), radius: 20)
                            .scaleEffect(pulseAnimation ? 1.05 : 0.95)
                            .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulseAnimation)
                        if showPercentage {
                            Text("\(percentageValue)%")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(theme.textSecondary.opacity(0.7))
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: 180)
            .padding(.bottom, theme.spacing.lg)

            // Title
            Text("ANALYZING STICK")
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
                // Match glow treatment from SharedValidationView / AICoachFlowProcessingView
                .shadow(color: Color.white.opacity(0.5), radius: 0, x: 0, y: 0)
                .shadow(color: Color.white.opacity(0.3), radius: 4, x: 0, y: 0)
                .shadow(color: theme.primary.opacity(0.4), radius: 10, x: 0, y: 2)
                .tracking(3)
                .padding(.bottom, 6)

            Text(currentPhase)
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(theme.primary)
                .tracking(1.5)

            Text(phaseDetail)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(theme.textSecondary.opacity(0.6))
                .padding(.top, 2)

            // Optional context chips
            if let chips = contextChips, !chips.isEmpty {
                HStack(spacing: 8) {
                    ForEach(chips.prefix(3), id: \.self) { chip in
                        Text(chip)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(theme.text)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(theme.surface.opacity(0.5)))
                            .overlay(Capsule().stroke(theme.divider.opacity(0.6), lineWidth: 1))
                    }
                }
                .padding(.top, 8)
            }

            Spacer()

            AnalysisDotsIndicator()
            .padding(.bottom, 20)

            // Network warnings removed

            // Percentage
            if showPercentage {
                Text("\(percentageValue)%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.textSecondary.opacity(0.4))
            }

            Spacer().frame(height: 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
        .onAppear {
            startAnimation()
            // Network checks removed
        }
        .onReceive(NotificationCenter.default.publisher(for: .aiUploadsComplete)) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                currentPhase = "UPLOADED VIDEO"
                phaseDetail = "Processing media for analysis..."
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .aiRequestSent)) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                currentPhase = "ANALYZING"
                phaseDetail = "AI is evaluating your technique..."
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .aiResponseReceived)) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                currentPhase = "FINALIZING"
                phaseDetail = "Applying recommendations..."
            }
        }
    }

    private func startAnimation() {
        withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
            dotScale = 1.3
        }
        // Use estimator if available; otherwise simulate phases
        animatePhases()
        animatePercentage(totalDuration: 38)
    }

    // MARK: - Phase Animations
    private func animatePhases() {
        let phases: [(title: String, detail: String, duration: Double, progress: Double)] = [
            ("INITIALIZING", "Preparing video frames...", 2.5, 0.08),
            ("EXTRACTING FRAMES", "Processing shot video...", 4.0, 0.20),
            ("TRACKING STICK & PUCK", "Detecting motion and contact...", 6.0, 0.40),
            ("EVALUATING SPECS", "Flex, length, curve, lie...", 7.0, 0.65),
            ("MATCHING PROFILES", "Comparing to playing context...", 6.0, 0.85),
            ("GENERATING RECOMMENDATIONS", "Personalizing for your style...", 6.0, 0.98),
            ("FINALIZING", "Completing analysis...", 2.0, 1.0)
        ]

        var accumulated: Double = 0
        withAnimation { pulseAnimation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { showPercentage = true } }

        for phase in phases {
            DispatchQueue.main.asyncAfter(deadline: .now() + accumulated) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    currentPhase = phase.title
                    phaseDetail = phase.detail
                }
                withAnimation(.linear(duration: phase.duration)) {
                    progressValue = phase.progress
                }
            }
            accumulated += phase.duration
        }
    }

    private func animatePercentage(totalDuration: Double) {
        let steps = 100
        let stepDur = totalDuration / Double(steps)
        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + (stepDur * Double(step))) {
                withAnimation(.linear(duration: 0.1)) {
                    let t = Double(step) / Double(steps)
                    let eased = t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
                    percentageValue = Int(eased * 100)
                }
            }
        }
    }

    private func updatePhaseFromProgress(_ progress: Double) {
        let phase: (String, String)
        switch progress {
        case 0..<0.08: phase = ("INITIALIZING", "Preparing video frames...")
        case 0.08..<0.20: phase = ("EXTRACTING FRAMES", "Processing shot video...")
        case 0.20..<0.40: phase = ("TRACKING STICK & PUCK", "Detecting motion and contact...")
        case 0.40..<0.65: phase = ("EVALUATING SPECS", "Flex, length, curve, lie...")
        case 0.65..<0.85: phase = ("MATCHING PROFILES", "Comparing to playing context...")
        case 0.85..<0.98: phase = ("GENERATING RECOMMENDATIONS", "Personalizing for your style...")
        default: phase = ("FINALIZING", "Completing analysis...")
        }
        withAnimation(.easeInOut(duration: 0.4)) {
            currentPhase = phase.0
            phaseDetail = phase.1
        }
    }

    // Network checks removed
}
