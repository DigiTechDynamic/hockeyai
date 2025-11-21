import SwiftUI

// MARK: - Onboarding Configuration
// ✅ THIS IS THE ONLY FILE YOU MODIFY FOR EACH APP
// Configure your onboarding screens, analytics, and UI customization here

struct OnboardingConfiguration {

    // MARK: - Screens Definition
    /// Define all onboarding screens here
    /// Each screen automatically gets analytics tracking
    static func createScreens(onComplete: @escaping () -> Void) -> [OnboardingScreenWrapper] {
        let totalSteps = 5  // Total number of screens

        // We'll use the existing OnboardingFlowView for now
        // This is a temporary solution until we refactor individual screens

        return []  // Return empty for now - we'll use the old OnboardingFlowView
    }

    // MARK: - UI Customization
    /// Background color for the entire onboarding flow
    static let backgroundColor: Color = Color.black

    /// Accent color for page indicators and buttons
    static let accentColor: Color = Color(hex: "#00FF7F")

    /// Show page indicators (dots at top)
    static let showPageIndicators: Bool = true

    /// Allow swipe navigation between screens
    static let allowSwipeNavigation: Bool = false

    // MARK: - Persistence
    /// UserDefaults key for completion status
    static let completionKey = "hasCompletedOnboarding"
}
