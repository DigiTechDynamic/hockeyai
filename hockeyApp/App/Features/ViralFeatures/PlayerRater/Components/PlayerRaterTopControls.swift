import SwiftUI

// MARK: - Player Rater Top Controls (Overlay)
/// Lightweight overlay controls that replace the fixed header.
/// Shows Back for onboarding (photo step) and Close for home/tryAgain contexts.
struct PlayerRaterTopControls: View {
    @Environment(\.theme) var theme

    let context: RaterContext
    let currentStep: PlayerRaterViewModel.RaterStep
    let onBack: () -> Void
    let onClose: () -> Void

    var body: some View {
        // Hide controls during analyzing step
        if currentStep != .analyzing {
            ZStack {
                // Subtle top gradient to ensure legibility over content
                LinearGradient(
                    colors: [Color.black.opacity(0.35), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)
                .ignoresSafeArea(edges: .top)

                HStack {
                    // Back (onboarding only, photo upload step only)
                    if shouldShowBackButton {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(theme.primary)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Back")
                    } else {
                        // Keep layout balance
                        Color.clear.frame(width: 44, height: 44)
                    }

                    Spacer()

                    // Right control: Close for non-onboarding OR Skip for onboarding
                    if shouldShowCloseButton {
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.textSecondary)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Close")
                    } else if shouldShowSkipTopRight {
                        Button(action: onBack) {
                            Text("Skip")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.textSecondary)
                                .frame(height: 44)
                                .padding(.horizontal, 8)
                        }
                        .accessibilityLabel("Skip")
                    } else {
                        Color.clear.frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.top, 6)
            }
        }
    }

    private var shouldShowBackButton: Bool {
        // Mirrors previous logic: only during onboarding on the photo step
        return context.showsCloseButton == false && currentStep == .photoUpload
    }

    private var shouldShowCloseButton: Bool {
        // Show close for non-onboarding contexts across steps
        // Hide on results screen to avoid duplicate with bottom button
        return context.showsCloseButton && currentStep != .results
    }

    private var shouldShowSkipTopRight: Bool {
        // Show Skip on top right for onboarding photo step
        return context.showsCloseButton == false && currentStep == .photoUpload
    }
}
