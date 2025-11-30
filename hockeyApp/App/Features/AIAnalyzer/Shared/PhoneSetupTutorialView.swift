import SwiftUI

// MARK: - Tutorial Flow Context
enum TutorialFlowContext {
    case aiCoach
    case shotRater
    case stickAnalyzer
    case skillCheck
    case standalone
}

// MARK: - Phone Setup Guide View
/// General-purpose phone setup guide for any recording scenario in the app
/// Shows users how to position their phone for self-recording without assistance
///
/// Design: Matches STY Rating page aesthetic with large image and green border
///
/// Usage:
/// - AI Analysis flows (shows before video capture if user hasn't dismissed)
/// - Workout recording (can be shown as a standalone help screen)
/// - Any feature requiring self-recorded video
///
/// Features:
/// - Clean full-screen layout with large instructional image
/// - Green bordered image (STY Rating style)
/// - Prominent "Continue" button at bottom
/// - "Don't Show Again" option (uses UserDefaults.phoneSetupTutorialDismissed)
/// - Close button (X) in top right
/// - No auto-advance - user has full control
struct PhoneSetupTutorialView: View {

    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) var theme

    let flowContext: TutorialFlowContext
    let onComplete: (TutorialFlowContext) -> Void

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .top) {
            // Unified themed background to match STY flow/shell
            ThemedBackground()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: theme.spacing.xl) {
                        // Title with glow effect (match STY Rating exactly)
                        VStack(spacing: theme.spacing.md) {
                            Text("Phone Setup")
                                .font(.system(size: 32, weight: .black))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color.white.opacity(0.95)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: theme.primary.opacity(0.6), radius: 20, x: 0, y: 0)
                                .shadow(color: theme.primary.opacity(0.3), radius: 30, x: 0, y: 5)
                                .multilineTextAlignment(.center)

                            Text("Set up your device for hands-free recording")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.text)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, theme.spacing.xl)
                        .padding(.top, theme.spacing.sm)

                        // Large image card with green border and glow
                        GeometryReader { geometry in
                            ZStack {
                                // Dark background
                                Color.black.opacity(0.3)

                                // Image with proper aspect ratio handling
                                Image("PhoneSetUp2")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            }
                            .frame(width: geometry.size.width, height: 460)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                theme.primary.opacity(0.5),
                                                theme.primary.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                            .shadow(color: theme.primary.opacity(0.3), radius: 16, x: 0, y: 6)
                            .shadow(color: Color.black.opacity(0.4), radius: 24, x: 0, y: 12)
                        }
                        .frame(height: 460)
                        .padding(.horizontal, theme.spacing.lg)

                        // Guidance description (below image) with info icon for consistency
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.textSecondary)

                            Text("No cameraman? Use a stable surface (or stacked pucks) to prop your phone. Make sure your body stays in frame and the area is well‑lit.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, theme.spacing.lg)
                        .padding(.top, -theme.spacing.sm)
                    }
                }

                // Bottom buttons (match "Done" button UI style)
                VStack(spacing: theme.spacing.md) {
                    Button {
                        onComplete(flowContext)
                    } label: {
                        ZStack {
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
                                                    theme.success.opacity(0.6),
                                                    theme.success.opacity(0.3)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )

                            Text("Continue")
                                .font(.system(size: 16, weight: .semibold))
                                .tracking(0.5)
                                .foregroundColor(theme.text)
                        }
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, theme.spacing.lg)

                    Button {
                        UserDefaults.standard.phoneSetupTutorialDismissed = true
                        onComplete(flowContext)
                    } label: {
                        Text("Don't Show Again")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                    }
                }
                .padding(.bottom, theme.spacing.md)
            }

            // Top overlay gradient to match PlayerRaterTopControls
            LinearGradient(
                colors: [Color.black.opacity(0.35), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 80)
            .ignoresSafeArea(edges: .top)
        }
        // Close button (top-right), overlaid above gradient for parity
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            .padding(.trailing, 16)
            .padding(.top, 16)
        }
    }
}

// MARK: - UserDefaults Extension
extension UserDefaults {
    private static let phoneSetupTutorialDismissedKey = "phoneSetupTutorialDismissed"

    var phoneSetupTutorialDismissed: Bool {
        get { bool(forKey: Self.phoneSetupTutorialDismissedKey) }
        set { set(newValue, forKey: Self.phoneSetupTutorialDismissedKey) }
    }

    // For testing/debugging - reset tutorial state
    func resetPhoneSetupTutorial() {
        phoneSetupTutorialDismissed = false
    }
}

// MARK: - Convenience Wrapper for Standalone Usage
/// Easy-to-use wrapper for showing phone setup guide anywhere in your app
///
/// Example usage in any view:
/// ```
/// @State private var showPhoneSetupGuide = false
///
/// Button("How to Record") {
///     showPhoneSetupGuide = true
/// }
/// .sheet(isPresented: $showPhoneSetupGuide) {
///     PhoneSetupGuideSheet()
/// }
/// ```
struct PhoneSetupGuideSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        PhoneSetupTutorialView(flowContext: .standalone) { _ in
            dismiss()
        }
    }
}

// MARK: - Preview
#Preview {
    // Reset for testing
    UserDefaults.standard.resetPhoneSetupTutorial()

    return PhoneSetupTutorialView(flowContext: .standalone) { context in
        print("Tutorial completed for context: \(context)")
    }
}
