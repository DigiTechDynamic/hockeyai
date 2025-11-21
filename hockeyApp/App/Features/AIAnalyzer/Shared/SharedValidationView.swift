import SwiftUI
import UIKit

// MARK: - Shared Validation View
/// A modern validation screen with haptic feedback used across all AI features
struct SharedValidationView: View {

    // MARK: - Properties
    @Binding var isValidating: Bool
    @Binding var validationResult: AIValidationService.ValidationResponse?
    @Binding var validationError: AIAnalyzerError?
    @Environment(\.theme) var theme

    let featureName: String // "AI Coach", "Shot Rater", or "Stick Analyzer"
    let onSuccess: () -> Void
    let onRetry: () -> Void
    let onCancel: () -> Void
    // Optional background action to allow continuing while user leaves the flow
    var onBackground: (() -> Void)? = nil
    // Whether to render an embedded header inside the content (use when container header is hidden)
    var showsEmbeddedHeader: Bool = false

    // MARK: - State
    @State private var pulseAnimation = false
    @State private var checkmarkScale = 0.0
    @State private var errorShake = 0.0
    @State private var progressValue: Double = 0.0
    @State private var statusMessage = "initializing"
    @State private var hapticTimer: Timer?
    @State private var showCancelConfirm = false

    // Network warnings removed

    // MARK: - Haptic Generator
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    // MARK: - Explicit Initializer (prevents memberwise init from exposing `theme` and fixes label order)
    init(
        isValidating: Binding<Bool>,
        validationResult: Binding<AIValidationService.ValidationResponse?>,
        validationError: Binding<AIAnalyzerError?>,
        featureName: String,
        onSuccess: @escaping () -> Void,
        onRetry: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        onBackground: (() -> Void)? = nil,
        showsEmbeddedHeader: Bool = false
    ) {
        self._isValidating = isValidating
        self._validationResult = validationResult
        self._validationError = validationError
        self.featureName = featureName
        self.onSuccess = onSuccess
        self.onRetry = onRetry
        self.onCancel = onCancel
        self.onBackground = onBackground
        self.showsEmbeddedHeader = showsEmbeddedHeader
    }

    var body: some View {
        ZStack {
            // No additional background - let parent container handle it

            VStack(spacing: 0) {
                // Embedded header (only when container header is hidden)
                if showsEmbeddedHeader {
                    ZStack {
                        // Title centered
                        Text(getMainTitle().capitalized)
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.white, Color.white.opacity(0.95)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color.white.opacity(0.5), radius: 0)
                            .shadow(color: Color.white.opacity(0.3), radius: 4)
                            .frame(maxWidth: .infinity)

                        // Cancel button positioned on the right
                        HStack {
                            Spacer()

                            Button(action: { showCancelConfirm = true }) {
                                Text("Cancel")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(theme.destructive)
                                    )
                                    .fixedSize() // This ensures the button only takes up the space it needs
                            }
                        }
                    }
                    .padding(.horizontal, theme.spacing.md)
                    .padding(.top, theme.spacing.md)

                    // Thin progress bar under header
                    ValidationProgressBar(progress: progressValue)
                        .frame(height: 6)
                        .padding(.horizontal, theme.spacing.md)
                        .padding(.top, 6)
                }

                Spacer()

                // Main content
                VStack(spacing: theme.spacing.xl) {
                    // Icon with animation
                    ZStack {
                        if validationError != nil {
                            // Error icon
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 64, weight: .medium))
                                .foregroundColor(theme.error)
                                .scaleEffect(checkmarkScale)
                                .rotationEffect(.degrees(errorShake))
                                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: checkmarkScale)
                                .animation(.spring(response: 0.2, dampingFraction: 0.2).repeatCount(2, autoreverses: true), value: errorShake)
                        } else if validationResult != nil {
                            // Success icon with enhanced glow like splash screen
                            ZStack {
                                // Outer glow layer (like splash screen)
                                Circle()
                                    .fill(theme.primary)
                                    .frame(width: 120, height: 120)
                                    .blur(radius: 30)
                                    .opacity(0.4)
                                    .scaleEffect(checkmarkScale * 1.2)

                                // Mid glow layer
                                Circle()
                                    .fill(theme.primary.opacity(0.3))
                                    .frame(width: 100, height: 100)
                                    .blur(radius: 15)
                                    .scaleEffect(checkmarkScale * 1.1)

                                // Checkmark icon with multiple shadows for depth
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 64, weight: .bold))
                                    .foregroundColor(theme.primary)
                                    .shadow(color: theme.primary.opacity(0.8), radius: 4)
                                    .shadow(color: theme.primary.opacity(0.5), radius: 10)
                                    .shadow(color: theme.primary.opacity(0.3), radius: 20)
                                    .scaleEffect(checkmarkScale)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: checkmarkScale)
                            }
                        } else {
                            // Loading shield with enhanced glow
                            ZStack {
                                // Glow background layer
                                Circle()
                                    .fill(theme.primary)
                                    .frame(width: 100, height: 100)
                                    .blur(radius: 25)
                                    .opacity(pulseAnimation ? 0.4 : 0.2)
                                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)

                                // Outer pulsing ring
                                Circle()
                                    .stroke(theme.primary.opacity(0.3), lineWidth: 2)
                                    .frame(width: 100, height: 100)
                                    .scaleEffect(pulseAnimation ? 1.15 : 1.0)
                                    .opacity(pulseAnimation ? 0 : 0.6)
                                    .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: pulseAnimation)

                                // Inner icon with shadows
                                Image(systemName: "shield.fill")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(theme.primary)
                                    .shadow(color: theme.primary.opacity(0.6), radius: 4)
                                    .shadow(color: theme.primary.opacity(0.4), radius: 10)
                                    .scaleEffect(pulseAnimation ? 1.05 : 0.95)
                                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulseAnimation)
                            }
                        }
                    }
                    .frame(height: 100)

                    // Text content with enhanced styling like HOCKEYAPP header
                    VStack(spacing: theme.spacing.sm) {
                        Text(getMainTitle())
                            .font(.system(size: 38, weight: .black))
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
                            .tracking(2) // Consistent athletic tracking

                        Text(getSubtitle())
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(theme.textSecondary)
                            .tracking(3)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, theme.spacing.xl)
                            .opacity(0.9)
                    }

                    // Status dots or action buttons
                    if isValidating {
                        ValidationDotsIndicator(theme: theme)
                            .padding(.top, theme.spacing.md)
                    } else if validationError != nil {
                        // Error actions
                        VStack(spacing: theme.spacing.md) {
                            Button(action: {
                                hapticTap()
                                onRetry()
                            }) {
                                Text("Try Again")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(theme.textOnPrimary)
                                    .frame(width: 200, height: 48)
                                    .background(theme.primary)
                                    .cornerRadius(theme.cornerRadius)
                            }

                            Button(action: {
                                hapticTap()
                                onCancel()
                            }) {
                                Text("Cancel")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(theme.textSecondary)
                            }
                        }
                        .padding(.top, theme.spacing.lg)
                    } else if validationResult != nil {
                        // Success - auto proceed after delay
                        EmptyView()
                    }
                }

                Spacer()

                // Network warning UI removed

                // Bottom actions (only during validation)
                if isValidating {
                    if let onBackground {
                        AppButton(
                            title: "Continue in Background",
                            action: { onBackground() },
                            style: .primaryNeon,
                            size: .large
                        )
                        .padding(.horizontal, theme.spacing.lg)
                        .padding(.bottom, theme.spacing.xl)
                    } else {
                        // No bottom controls when backgrounding isn't supported in this flow
                        Spacer(minLength: theme.spacing.xl)
                    }
                }
            }
        }
        .onAppear {
            // Start validation UI and show non-blocking cellular banner as soon as we land here
            startValidation()
            AINetworkPreflight.showCellularNoticeIfNeeded()
        }
        .onDisappear {
            stopHaptics()
        }
        
        .onChange(of: validationResult) { newValue in
            print("📊 [SharedValidationView] validationResult changed: \(newValue?.is_valid ?? false)")
            if newValue != nil {
                handleSuccess()
            }
        }
        .onChange(of: validationError) { newValue in
            if newValue != nil {
                handleError()
            }
        }
        .confirmationDialog(
            "Cancel analysis?",
            isPresented: $showCancelConfirm,
            titleVisibility: .visible
        ) {
            Button("Stop Analysis", role: .destructive) {
                // Stop validation immediately
                isValidating = false
                stopHaptics()
                // Then call the cancel callback
                onCancel()
                NotificationCenter.default.post(name: Notification.Name("AIFlowCancel"), object: featureName.lowercased())
            }
            Button("Keep Running", role: .cancel) {}
        }
        
    }

    // MARK: - Helper Methods

    private func getMainTitle() -> String {
        if validationError != nil {
            return "VALIDATION FAILED"
        } else if validationResult != nil {
            return "SHOT VALIDATED"
        } else {
            return "VALIDATING SHOT"
        }
    }

    private func getSubtitle() -> String {
        if let error = validationError {
            switch error {
            case .invalidContent(let reason):
                if case .aiDetectedInvalidContent(let message) = reason {
                    return message
                }
                return "Invalid content detected"
            case .networkIssue:
                return "Network connection issue"
            case .aiProcessingFailed(let message):
                return message
            default:
                return "Unable to validate shot"
            }
        } else if let result = validationResult {
            let confidence = Int(result.confidence * 100)
            return "CONFIDENCE: \(confidence)%"
        } else {
            return statusMessage.uppercased()
        }
    }

    private func startValidation() {
        // Start animations
        withAnimation {
            pulseAnimation = true
        }

        // Start haptic feedback
        impactGenerator.prepare()
        startHapticPulse()

        // Animate progress
        animateProgress()

        // Update status messages
        updateStatusMessages()
    }

    private func startHapticPulse() {
        // Create a gentle haptic pulse every second
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if isValidating {
                impactGenerator.impactOccurred(intensity: 0.5)
            }
        }
    }

    private func stopHaptics() {
        hapticTimer?.invalidate()
        hapticTimer = nil
    }

    private func animateProgress() {
        // Animate progress bar over 3-5 seconds
        withAnimation(.easeInOut(duration: 3)) {
            progressValue = 0.9
        }
    }

    private func updateStatusMessages() {
        let messages = [
            "analyzing video frames",
            "detecting hockey motion",
            "checking shot validity",
            "processing results"
        ]

        var index = 0
        Timer.scheduledTimer(withTimeInterval: 1.8, repeats: true) { timer in
            if !isValidating {
                timer.invalidate()
                return
            }

            withAnimation(.easeInOut(duration: 0.3)) {
                statusMessage = messages[index % messages.count]
            }
            index += 1
        }
    }

    private func handleSuccess() {
        print("✅ [SharedValidationView] handleSuccess called")
        stopHaptics()

        // Success haptics
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.success)

        // Animate checkmark
        withAnimation {
            progressValue = 1.0
            checkmarkScale = 1.0
        }

        // Auto-proceed after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            print("🚀 [SharedValidationView] Calling onSuccess callback")
            onSuccess()
        }
    }

    private func handleError() {
        stopHaptics()

        // Error haptics
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.error)

        // Animate error
        withAnimation {
            progressValue = 0
            checkmarkScale = 1.0
            errorShake = 5.0
        }

        // Reset shake
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            errorShake = 0
        }
    }

    private func hapticTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    // Network checks removed
}

// MARK: - Progress Bar Component
struct ValidationProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(Color.gray.opacity(0.2))

                // Progress
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.7), .yellow, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(progress))
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
    }
}

// MARK: - Dots Indicator Component
struct ValidationDotsIndicator: View {
    let theme: any AppTheme
    @State private var activeIndex = 0

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<3) { index in
                ZStack {
                    // Glow effect for active dot
                    if activeIndex == index {
                        Circle()
                            .fill(theme.primary)
                            .frame(width: 12, height: 12)
                            .blur(radius: 6)
                            .opacity(0.6)
                    }

                    // Main dot
                    Circle()
                        .fill(activeIndex == index ? theme.primary : theme.divider)
                        .frame(width: 8, height: 8)
                        .scaleEffect(activeIndex == index ? 1.3 : 1.0)
                        .shadow(color: activeIndex == index ? theme.primary.opacity(0.6) : .clear, radius: 4)
                }
                .animation(.easeInOut(duration: 0.3), value: activeIndex)
            }
        }
        .onAppear {
            animateDots()
        }
    }

    private func animateDots() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            withAnimation {
                activeIndex = (activeIndex + 1) % 3
            }
        }
    }
}

// MARK: - Preview Provider
struct SharedValidationView_Previews: PreviewProvider {
    static var previews: some View {
        SharedValidationView(
            isValidating: .constant(true),
            validationResult: .constant(nil),
            validationError: .constant(nil),
            featureName: "Shot Rater",
            onSuccess: {},
            onRetry: {},
            onCancel: {}
        )
        .preferredColorScheme(.dark)
    }
}
