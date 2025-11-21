import SwiftUI

// MARK: - AI Analysis Error View
/// Premium error view with glassmorphic design and animated elements
public struct AIAnalysisErrorView: View {
    let error: Error
    let featureName: String
    let onRetry: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.theme) var theme
    @State private var isExpanded = false
    @State private var iconAnimation = false
    @State private var pulseAnimation = false
    @State private var contentAppeared = false
    @State private var buttonScale = 1.0
    @State private var particleAnimation = false
    @State private var buttonPulse = false
    
    public init(
        error: Error,
        featureName: String,
        onRetry: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.error = error
        self.featureName = featureName
        self.onRetry = onRetry
        self.onCancel = onCancel
    }
    
    public var body: some View {
        ZStack {
            // Animated Background Gradient
            backgroundGradient
            
            // Floating Particles Effect
            GeometryReader { geometry in
                ForEach(0..<8, id: \.self) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [errorColor.opacity(0.3), errorColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: CGFloat.random(in: 30...80))
                        .position(
                            x: geometry.size.width * CGFloat.random(in: 0.1...0.9),
                            y: particleAnimation ? -100 : geometry.size.height + 100
                        )
                        .blur(radius: 8)
                        .animation(
                            Animation.linear(duration: Double.random(in: 15...25))
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.5),
                            value: particleAnimation
                        )
                }
            }
            .opacity(0.3)
            
            // Main Content Card
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)
                
                // Glassmorphic Card
                VStack(spacing: 28) {
                    // Header Section
                    VStack(spacing: 20) {
                        // Animated Icon Container
                        ZStack {
                            // Glow Effect
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [errorColor.opacity(0.3), Color.clear],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 60
                                    )
                                )
                                .frame(width: 140, height: 140)
                                .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                                .opacity(pulseAnimation ? 0 : 0.8)
                                .animation(
                                    Animation.easeInOut(duration: 2)
                                        .repeatForever(autoreverses: false),
                                    value: pulseAnimation
                                )
                            
                            // Icon Background
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            errorColor.opacity(0.2),
                                            errorColor.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    errorColor.opacity(0.5),
                                                    errorColor.opacity(0.2)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                            
                            // Error Icon
                            Image(systemName: errorIcon)
                                .font(.system(size: 48, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [errorColor, errorColor.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .rotationEffect(.degrees(iconAnimation ? 0 : -5))
                                .animation(
                                    Animation.easeInOut(duration: 0.5)
                                        .repeatForever(autoreverses: true),
                                    value: iconAnimation
                                )
                        }
                        
                        // Error Title with glow effect like header
                        ZStack {
                            // Glow layer
                            Text(errorTitle)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(theme.text)
                                .shadow(color: theme.text.opacity(0.3), radius: 8)
                                .shadow(color: theme.text.opacity(0.2), radius: 16)
                                .blur(radius: 0.5)
                            
                            // Main text
                            Text(errorTitle)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [theme.text, theme.text.opacity(0.95)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        .multilineTextAlignment(.center)
                        .scaleEffect(contentAppeared ? 1 : 0.9)
                        .opacity(contentAppeared ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: contentAppeared)
                        
                        // Error Message with Softer Tone
                        Text(friendlyErrorMessage)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil) // Allow unlimited lines
                            .fixedSize(horizontal: false, vertical: true) // Allow vertical expansion
                            .padding(.horizontal, 24)
                            .lineSpacing(4)
                            .scaleEffect(contentAppeared ? 1 : 0.9)
                            .opacity(contentAppeared ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: contentAppeared)
                    }
                    
                    // Interactive Tips Section
                    if let tips = errorTips, !tips.isEmpty {
                        VStack(spacing: 0) {
                            Button(action: { 
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    isExpanded.toggle() 
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(theme.success)
                                    
                                    Text("Quick Tips")
                                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                                        .foregroundColor(theme.text)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(theme.textSecondary)
                                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    theme.surface.opacity(0.8),
                                                    theme.surface.opacity(0.6)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [
                                                            theme.primary.opacity(0.3),
                                                            theme.primary.opacity(0.1)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1
                                                )
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if isExpanded {
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                                        HStack(alignment: .top, spacing: 14) {
                                            ZStack {
                                                Circle()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [
                                                                theme.success.opacity(0.2),
                                                                theme.success.opacity(0.1)
                                                            ],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 24, height: 24)
                                                
                                                Text("\(index + 1)")
                                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                                    .foregroundColor(theme.success)
                                            }
                                            
                                            Text(tip)
                                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                                .foregroundColor(theme.text.opacity(0.9))
                                                .lineSpacing(3)
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal, 20)
                                        .transition(
                                            .asymmetric(
                                                insertion: .move(edge: .top).combined(with: .opacity),
                                                removal: .opacity
                                            )
                                        )
                                        .animation(
                                            .spring(response: 0.4, dampingFraction: 0.8)
                                                .delay(Double(index) * 0.05),
                                            value: isExpanded
                                        )
                                    }
                                }
                                .padding(.top, 16)
                                .padding(.bottom, 8)
                            }
                        }
                        .scaleEffect(contentAppeared ? 1 : 0.9)
                        .opacity(contentAppeared ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: contentAppeared)
                    }
                }
                .padding(.vertical, 36)
                .padding(.horizontal, 24)
                .background(
                    ZStack {
                        // Glassmorphic Background
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        theme.surface.opacity(0.95),
                                        theme.surface.opacity(0.85)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(Material.ultraThin)
                            )
                        
                        // Gradient Overlay
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.05),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .center
                                )
                            )
                        
                        // Border
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        theme.primary.opacity(0.3),
                                        theme.primary.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                )
                .shadow(color: theme.primary.opacity(0.1), radius: 20, x: 0, y: 10)
                .scaleEffect(contentAppeared ? 1 : 0.95)
                .opacity(contentAppeared ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: contentAppeared)
                .padding(.horizontal, 20)
                
                Spacer(minLength: 40)
                
                // Single Action Button with glassmorphic style
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        buttonScale = 0.95
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        buttonScale = 1.0
                        onRetry()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: retryIcon)
                            .font(.system(size: 20, weight: .bold))
                        
                        Text(retryButtonText)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        theme.surface.opacity(0.8),
                                        theme.surface.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                theme.primary.opacity(0.3),
                                                theme.primary.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .foregroundColor(theme.text)
                    .scaleEffect(buttonScale)
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(contentAppeared ? 1 : 0.8)
                .opacity(contentAppeared ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: contentAppeared)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                }
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            withAnimation {
                iconAnimation = true
                pulseAnimation = true
                contentAppeared = true
                particleAnimation = true
                buttonPulse = true
            }
        }
    }
    
    // MARK: - Background Gradient
    private var backgroundGradient: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    theme.background,
                    theme.background.opacity(0.95),
                    theme.surface
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle radial glow
            RadialGradient(
                colors: [
                    errorColor.opacity(0.05),
                    Color.clear
                ],
                center: .top,
                startRadius: 100,
                endRadius: 400
            )
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Computed Properties
    
    private var friendlyErrorMessage: String {
        // Check for new unified error first
        if let analyzerError = error as? AIAnalyzerError {
            switch analyzerError {
            case .networkIssue:
                return "Unable to connect to the analysis service. Please check your internet connection and try again."
            case .aiProcessingFailed(let details):
                return details.isEmpty ? "The analysis couldn't be completed. Please try again." : details
            case .invalidContent(let reason):
                // The AI provides the actual message about what it detected
                return analyzerError.failureReason ?? "Please record a complete hockey shot for analysis."
            case .validationParsingFailed(let details):
                return details
            case .analysisParsingFailed(let details):
                return details
            }
        }
        return errorMessage
    }
    
    private var retryIcon: String {
        if let analyzerError = error as? AIAnalyzerError {
            switch analyzerError {
            case .invalidContent:
                return "video.fill"
            default:
                return "arrow.clockwise"
            }
        }
        return "arrow.clockwise"
    }
    
    private var errorIcon: String {
        if let analyzerError = error as? AIAnalyzerError {
            switch analyzerError {
            case .networkIssue:
                return "exclamationmark.triangle"
            case .aiProcessingFailed:
                return "exclamationmark.circle.fill"
            case .invalidContent:
                return "exclamationmark.triangle.fill"
            case .validationParsingFailed:
                return "doc.text.magnifyingglass"
            case .analysisParsingFailed:
                return "doc.text.magnifyingglass"
            }
        }
        return "exclamationmark.circle.fill"
    }
    
    private var errorColor: Color {
        // Use a strong red color for clear error indication
        return Color(red: 0.86, green: 0.08, blue: 0.24) // Crimson red #DC143C
    }
    
    private var errorTitle: String {
        if let analyzerError = error as? AIAnalyzerError {
            switch analyzerError {
            case .networkIssue:
                return "Connection Error"
            case .aiProcessingFailed:
                return "Processing Failed"
            case .invalidContent:
                return "Invalid Video"
            case .validationParsingFailed:
                return "Validation Failed"
            case .analysisParsingFailed:
                return "Processing Failed"
            }
        }
        return "Error"
    }
    
    private var errorMessage: String {
        // Check for new unified error first
        if let analyzerError = error as? AIAnalyzerError {
            // Use failureReason to get the actual AI message, not the generic title
            return analyzerError.failureReason ?? analyzerError.localizedDescription
        }
        return error.localizedDescription
    }
    
    private var errorTips: [String]? {
        // Check for new unified error first
        if let analyzerError = error as? AIAnalyzerError {
            switch analyzerError {
            case .invalidContent(let reason):
                // Get the specific tips for the invalid content type
                return reason.tips
            case .networkIssue:
                return [
                    "Check your internet connection",
                    "Try moving closer to your router",
                    "Disable VPN if enabled",
                    "Restart the app and try again"
                ]
            case .aiProcessingFailed:
                return [
                    "Try recording a shorter video (under 30 seconds)",
                    "Ensure good lighting",
                    "Keep the camera steady",
                    "Make sure the shot is clearly visible"
                ]
            case .validationParsingFailed:
                return [
                    "This is usually temporary",
                    "Try again in a few seconds",
                    "Make sure you have good internet",
                    "Contact support if it persists"
                ]
            case .analysisParsingFailed:
                return [
                    "The analysis completed but couldn't be displayed",
                    "Try analyzing again",
                    "Your videos were valid",
                    "This is a temporary processing issue"
                ]
            }
        }
        return nil
    }
    
    private var retryButtonText: String {
        if let analyzerError = error as? AIAnalyzerError {
            switch analyzerError {
            case .invalidContent:
                return "Record New Video"
            default:
                return "Try Again"
            }
        }
        return "Try Again"
    }
}

// MARK: - Preview
struct AIAnalysisErrorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AIAnalysisErrorView(
                error: AIAnalyzerError.invalidContent(.aiDetectedInvalidContent("This appears to be basketball. Please record a hockey shot.")),
                featureName: "AI Shot Coach",
                onRetry: {},
                onCancel: {}
            )
            .environment(\.theme, UnifiedTheme())
            .preferredColorScheme(.dark)
            .previewDisplayName("Validation Error")
            
            AIAnalysisErrorView(
                error: AIAnalyzerError.networkIssue,
                featureName: "Shot Rater",
                onRetry: {},
                onCancel: {}
            )
            .environment(\.theme, UnifiedTheme())
            .preferredColorScheme(.dark)
            .previewDisplayName("Network Error")
        }
    }
}
