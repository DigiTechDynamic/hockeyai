import SwiftUI

// MARK: - AI Service Error Type
/// Common error types for AI services - portable across apps
public enum AIServiceErrorType: Equatable {
    case serverOverloaded       // 503 - Server is busy
    case rateLimitExceeded      // 429 - Too many requests
    case networkError           // No connection
    case timeout                // Request took too long
    case processingFailed       // Generic processing failure
    case invalidContent(String, [String]) // Invalid input with message and tips
    case unknown(String)        // Unknown error with message

    public static func == (lhs: AIServiceErrorType, rhs: AIServiceErrorType) -> Bool {
        switch (lhs, rhs) {
        case (.serverOverloaded, .serverOverloaded),
             (.rateLimitExceeded, .rateLimitExceeded),
             (.networkError, .networkError),
             (.timeout, .timeout),
             (.processingFailed, .processingFailed):
            return true
        case (.invalidContent(let lMsg, _), .invalidContent(let rMsg, _)):
            return lMsg == rMsg
        case (.unknown(let lMsg), .unknown(let rMsg)):
            return lMsg == rMsg
        default:
            return false
        }
    }

    /// Create from error message
    public static func from(_ error: Error) -> AIServiceErrorType {
        let message = error.localizedDescription.lowercased()

        if message.contains("overloaded") || message.contains("503") {
            return .serverOverloaded
        } else if message.contains("rate limit") || message.contains("429") || message.contains("quota") {
            return .rateLimitExceeded
        } else if message.contains("network") || message.contains("internet") || message.contains("connection") || message.contains("offline") {
            return .networkError
        } else if message.contains("timeout") || message.contains("timed out") {
            return .timeout
        } else {
            return .processingFailed
        }
    }

    var icon: String {
        switch self {
        case .serverOverloaded: return "server.rack"
        case .rateLimitExceeded: return "clock.badge.exclamationmark"
        case .networkError: return "wifi.exclamationmark"
        case .timeout: return "hourglass"
        case .processingFailed: return "exclamationmark.triangle"
        case .invalidContent: return "video.slash"
        case .unknown: return "exclamationmark.circle"
        }
    }

    var title: String {
        switch self {
        case .serverOverloaded: return "Server Busy"
        case .rateLimitExceeded: return "Too Many Requests"
        case .networkError: return "No Connection"
        case .timeout: return "Request Timeout"
        case .processingFailed: return "Processing Failed"
        case .invalidContent: return "Invalid Video"
        case .unknown: return "Something Went Wrong"
        }
    }

    var message: String {
        switch self {
        case .serverOverloaded:
            return "The AI service is experiencing high demand. This usually resolves within a few minutes."
        case .rateLimitExceeded:
            return "You've made too many requests. Please wait a moment before trying again."
        case .networkError:
            return "Unable to connect. Please check your internet connection."
        case .timeout:
            return "The request took too long to complete. Please try again."
        case .processingFailed:
            return "We couldn't process your request. Please try again."
        case .invalidContent(let msg, _):
            return msg
        case .unknown(let errorMessage):
            return errorMessage
        }
    }

    var suggestion: String {
        switch self {
        case .serverOverloaded:
            return "Try again in a minute or two"
        case .rateLimitExceeded:
            return "Wait 30 seconds before retrying"
        case .networkError:
            return "Check Wi-Fi or cellular connection"
        case .timeout:
            return "Try with a smaller file or better connection"
        case .processingFailed:
            return "Try recording a new video"
        case .invalidContent:
            return "Record a valid hockey video"
        case .unknown:
            return "Try again or contact support"
        }
    }

    var tips: [String]? {
        switch self {
        case .invalidContent(_, let tips):
            return tips.isEmpty ? nil : tips
        case .networkError:
            return ["Check your Wi-Fi or cellular connection", "Try moving closer to your router", "Disable VPN if enabled"]
        default:
            return nil
        }
    }

    var accentColor: Color {
        switch self {
        case .serverOverloaded: return .orange
        case .rateLimitExceeded: return .yellow
        case .networkError: return .red
        case .timeout: return .orange
        case .processingFailed: return .red
        case .invalidContent: return .orange
        case .unknown: return .red
        }
    }

    var retryButtonText: String {
        switch self {
        case .invalidContent:
            return "Record New Video"
        default:
            return "Try Again"
        }
    }

    var retryIcon: String {
        switch self {
        case .invalidContent:
            return "video.fill"
        default:
            return "arrow.clockwise"
        }
    }
}

// MARK: - AI Service Error View
/// Reusable error view for AI service failures
/// Designed to be portable across different apps using AIFeatureKit
public struct AIServiceErrorView: View {
    let errorType: AIServiceErrorType
    let onRetry: () -> Void
    let onDismiss: (() -> Void)?

    // Animation states
    @State private var iconBounce = false
    @State private var contentAppeared = false
    @State private var showTips = false

    public init(
        errorType: AIServiceErrorType,
        onRetry: @escaping () -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        self.errorType = errorType
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }

    /// Convenience initializer from Error
    public init(
        error: Error,
        onRetry: @escaping () -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        self.errorType = AIServiceErrorType.from(error)
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Main content
            VStack(spacing: 28) {
                // Icon with animated background
                ZStack {
                    // Pulsing glow
                    Circle()
                        .fill(errorType.accentColor.opacity(0.15))
                        .frame(width: 140, height: 140)
                        .scaleEffect(iconBounce ? 1.1 : 0.95)
                        .animation(
                            .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                            value: iconBounce
                        )

                    // Icon background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    errorType.accentColor.opacity(0.2),
                                    errorType.accentColor.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    // Icon
                    Image(systemName: errorType.icon)
                        .font(.system(size: 44, weight: .medium))
                        .foregroundColor(errorType.accentColor)
                        .offset(y: iconBounce ? -2 : 2)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: iconBounce
                        )
                }
                .opacity(contentAppeared ? 1 : 0)
                .scaleEffect(contentAppeared ? 1 : 0.8)

                // Text content
                VStack(spacing: 14) {
                    Text(errorType.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(errorType.message)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 24)
                }
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 20)

                // Tips section (expandable)
                if let tips = errorType.tips {
                    VStack(spacing: 0) {
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showTips.toggle()
                            }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.yellow)

                                Text("Quick Tips")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white.opacity(0.5))
                                    .rotationEffect(.degrees(showTips ? 90 : 0))
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        if showTips {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                                    HStack(alignment: .top, spacing: 12) {
                                        Text("\(index + 1)")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.yellow)
                                            .frame(width: 20, height: 20)
                                            .background(Circle().fill(Color.yellow.opacity(0.2)))

                                        Text(tip)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                            .lineSpacing(2)

                                        Spacer()
                                    }
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.top, 14)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .opacity(contentAppeared ? 1 : 0)
                } else {
                    // Simple suggestion pill (no tips)
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.yellow)

                        Text(errorType.suggestion)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 20)
                }
            }

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                // Retry button
                Button(action: onRetry) {
                    HStack(spacing: 10) {
                        Image(systemName: errorType.retryIcon)
                            .font(.system(size: 18, weight: .bold))
                        Text(errorType.retryButtonText)
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "32CD32"), Color(hex: "28A428")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(28)
                    .shadow(color: Color(hex: "32CD32").opacity(0.4), radius: 12, y: 6)
                }

                // Dismiss button (optional)
                if let onDismiss = onDismiss {
                    Button(action: onDismiss) {
                        Text("Close")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(25)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .opacity(contentAppeared ? 1 : 0)
            .offset(y: contentAppeared ? 0 : 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                Color.black

                // Subtle gradient overlay
                RadialGradient(
                    colors: [errorType.accentColor.opacity(0.08), Color.clear],
                    center: .top,
                    startRadius: 50,
                    endRadius: 400
                )
            }
            .ignoresSafeArea()
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                contentAppeared = true
            }
            withAnimation(.easeInOut(duration: 1.5).delay(0.3)) {
                iconBounce = true
            }
        }
    }
}

// MARK: - AIAnalyzerError Conversion
extension AIServiceErrorType {
    /// Convert from AIAnalyzerError for seamless integration
    public static func from(analyzerError: Any) -> AIServiceErrorType {
        // Use Mirror to inspect the error without importing the type directly
        let mirror = Mirror(reflecting: analyzerError)
        let errorString = String(describing: analyzerError)

        if errorString.contains("networkIssue") {
            return .networkError
        } else if errorString.contains("invalidContent") {
            // Extract the message from the associated value
            for child in mirror.children {
                if let reason = child.value as? Any {
                    let reasonMirror = Mirror(reflecting: reason)
                    for reasonChild in reasonMirror.children {
                        if let message = reasonChild.value as? String {
                            return .invalidContent(message, [
                                "Use a hockey stick and puck",
                                "Record on ice, street, or synthetic surface",
                                "Ensure the full shooting motion is visible",
                                "Use good lighting and keep camera steady"
                            ])
                        }
                    }
                }
            }
            return .invalidContent("Invalid video content", [])
        } else if errorString.contains("aiProcessingFailed") {
            return .processingFailed
        } else if errorString.contains("validationParsingFailed") || errorString.contains("analysisParsingFailed") {
            return .processingFailed
        }

        return .processingFailed
    }
}

// MARK: - Preview
#if DEBUG
struct AIServiceErrorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AIServiceErrorView(
                errorType: .serverOverloaded,
                onRetry: {},
                onDismiss: {}
            )
            .previewDisplayName("Server Overloaded")

            AIServiceErrorView(
                errorType: .invalidContent("This video doesn't appear to show a hockey shot.", [
                    "Use a hockey stick and puck",
                    "Record on ice or street surface",
                    "Show the full shooting motion"
                ]),
                onRetry: {},
                onDismiss: {}
            )
            .previewDisplayName("Invalid Content")

            AIServiceErrorView(
                errorType: .networkError,
                onRetry: {},
                onDismiss: nil
            )
            .previewDisplayName("Network Error")
        }
    }
}
#endif
