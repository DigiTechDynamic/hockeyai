import SwiftUI
import Combine

// MARK: - Player Rater Analyzing/Validation View
/// Styled to match AIAnalyzer's SharedValidationView, adapted for Player Rater
struct PlayerRaterAnalyzingView: View {
    @Environment(\.theme) var theme
    @ObservedObject var viewModel: PlayerRaterViewModel

    // Animation/state
    @State private var pulseAnimation = false
    @State private var checkmarkScale = 0.0
    @State private var progressValue: Double = 0.0
    @State private var statusMessage = "Initializing..."
    @State private var showCancelConfirm = false

    var body: some View {
        ZStack {
            // Dim anything behind this screen to avoid visual bleed-through
            theme.background.opacity(AppSettings.Constants.Opacity.almostOpaque)
                .ignoresSafeArea()

            // Add a subtle radial glow on top for depth
            RadialGradient(
                colors: [theme.primary.opacity(0.08), Color.clear],
                center: .topLeading,
                startRadius: 10,
                endRadius: 300
            )
            .ignoresSafeArea()

            // Main centered content
            VStack(spacing: theme.spacing.lg) {
                // Centerpiece icon + glow (mirrors SharedValidationView tone)
                ZStack {
                    // Glow background layer
                    Circle()
                        .fill(theme.primary)
                        .frame(width: 120, height: 120)
                        .blur(radius: 28)
                        .opacity(pulseAnimation ? 0.45 : 0.22)
                        .scaleEffect(pulseAnimation ? 1.18 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)

                    // Solid isolation disc to prevent background showing through the icon (no material)
                    Circle()
                        .fill(Color.black.opacity(0.9))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle().stroke(theme.primary.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.25), radius: 12)

                    // Outer pulsing ring
                    Circle()
                        .stroke(theme.primary.opacity(0.32), lineWidth: 2)
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulseAnimation ? 1.12 : 1.0)
                        .opacity(pulseAnimation ? 0.0 : 0.6)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: pulseAnimation)

                    // Inner icon with athletic shadows (use sparkles to suggest rating)
                    if progressValue < 1.0 {
                        Image(systemName: "sparkles")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(theme.primary)
                            .shadow(color: theme.primary.opacity(0.6), radius: 4)
                            .shadow(color: theme.primary.opacity(0.4), radius: 10)
                            .scaleEffect(pulseAnimation ? 1.04 : 0.96)
                            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulseAnimation)
                            .zIndex(1)
                    }

                    // Success check overlay
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(theme.primary)
                        .shadow(color: theme.primary.opacity(0.8), radius: 4)
                        .shadow(color: theme.primary.opacity(0.5), radius: 10)
                        .shadow(color: theme.primary.opacity(0.3), radius: 20)
                        .scaleEffect(checkmarkScale)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: checkmarkScale)
                        .opacity(checkmarkScale > 0 ? 1 : 0)
                }
                .frame(width: 130, height: 130)

                // Title + subtitle
                VStack(spacing: theme.spacing.sm) {
                    Text(progressValue >= 1.0 ? "Player Verified" : "Analyzing Photo")
                        .font(.system(size: 38, weight: .black))
                        .glowingHeaderText()
                        .tracking(2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(progressValue >= 1.0 ? "Ready for results" : statusMessage)
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(theme.textSecondary)
                        .tracking(3)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, theme.spacing.xl)
                        .opacity(0.9)
                }
            }

            // Bottom dots indicator
            VStack {
                Spacer()
                ValidationDotsIndicator(theme: theme)
                    .padding(.bottom, 60)
            }

            // Cancel button removed here; added as overlay below for proper pinning
        }
        // Pin cancel button to the top-right safe area without shifting layout
        .overlay(alignment: .topTrailing) {
            Button(action: { showCancelConfirm = true }) {
                Text("Cancel")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.red.opacity(0.95)))
            }
            .padding(.top, 8)
            .padding(.trailing, theme.spacing.lg)
        }
        .onAppear {
            // Track analyzing step (Step 4 in funnel)
            if viewModel.context == .onboarding {
                STYValidationAnalytics.trackAnalyzing()
            } else {
                STYCheckAnalytics.trackAnalyzing()
            }

            startAnimations()
            startStatusCycling()
            progressValue = viewModel.analysisProgress
        }
        .onReceive(viewModel.$analysisProgress) { newValue in
            withAnimation(.easeInOut(duration: 0.2)) {
                progressValue = newValue
            }
            if newValue >= 1.0 {
                withAnimation { checkmarkScale = 1.0 }
            }
        }
        .confirmationDialog(
            "Cancel analysis?",
            isPresented: $showCancelConfirm,
            titleVisibility: .visible
        ) {
            Button("Stop Analysis", role: .destructive) {
                viewModel.dismiss()
            }
            Button("Keep Running", role: .cancel) {}
        }
        .trackScreen("sty_check_analyzing")
    }

    private func startAnimations() {
        withAnimation { pulseAnimation = true }
    }

    private func startStatusCycling() {
        let messages = [
            "Centering subject",
            "Detecting person",
            "Checking lighting and clarity",
            "Spotting hockey gear",
            "Extracting key details",
            "Preparing your rating"
        ]
        var index = 0
        statusMessage = messages.first ?? "Analyzing"

        Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { timer in
            if progressValue >= 1.0 { timer.invalidate(); return }
            withAnimation(.easeInOut(duration: 0.3)) {
                statusMessage = messages[index % messages.count]
            }
            index += 1
        }
    }
}
