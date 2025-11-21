import SwiftUI

// MARK: - Onboarding Screen Protocol
// ⚠️ NEVER MODIFY THIS FILE - Reusable across ALL apps

/// Minimal protocol that any onboarding screen must conform to
/// This keeps screens simple and focused on UI only
protocol OnboardingScreen: View {
    /// Unique identifier for this screen (used for analytics)
    var screenID: String { get }

    /// Callback when user taps continue/next button
    var onContinue: () -> Void { get }

    /// Optional: Called when screen appears (for custom setup)
    func onScreenAppear()

    /// Optional: Called when screen disappears (for cleanup)
    func onScreenDisappear()
}

// MARK: - Default Implementations
extension OnboardingScreen {
    /// Default: Do nothing on appear
    func onScreenAppear() {}

    /// Default: Do nothing on disappear
    func onScreenDisappear() {}
}
