import Foundation

// MARK: - Onboarding Analytics
// ⚠️ NEVER MODIFY THIS FILE - Reusable across ALL apps

/// Centralized analytics tracking for onboarding flow
/// Automatically tracks funnel progression, screen views, and completion
enum OnboardingAnalytics {

    // MARK: - Funnel Tracking

    /// Track when onboarding starts (Step 1)
    static func trackStart() {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "onboarding",
            step: "started",
            stepNumber: 1,
            totalSteps: 5
        )

        #if DEBUG
        print("[Onboarding] 📊 Started (Step 1/5)")
        #endif
    }

    /// Track when user views welcome screen (Step 2)
    static func trackWelcome() {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "onboarding",
            step: "welcome",
            stepNumber: 2,
            totalSteps: 5
        )

        #if DEBUG
        print("[Onboarding] 📊 Welcome screen (Step 2/5)")
        #endif
    }

    /// Track when a specific screen is viewed
    /// Called automatically by OnboardingFlowContainer
    static func trackScreenView(screenID: String, screenIndex: Int, totalScreens: Int) {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "onboarding",
            step: screenID,
            stepNumber: screenIndex + 1,
            totalSteps: totalScreens
        )

        #if DEBUG
        print("[Onboarding] 📊 Screen viewed: \(screenID) (\(screenIndex + 1)/\(totalScreens))")
        #endif
    }

    /// Track when user continues from a screen
    /// Call this from onContinue closure in OnboardingConfiguration
    static func trackContinue(screenID: String, stepNumber: Int, totalSteps: Int) {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "onboarding",
            step: "\(screenID)_continue",
            stepNumber: stepNumber,
            totalSteps: totalSteps
        )

        #if DEBUG
        print("[Onboarding] 📊 Continued from: \(screenID)")
        #endif
    }

    /// Track when user enters STY Validation during onboarding (Step 3)
    static func trackSTYValidation() {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "onboarding",
            step: "sty_validation",
            stepNumber: 3,
            totalSteps: 5
        )

        #if DEBUG
        print("[Onboarding] 📊 STY Validation started (Step 3/5)")
        #endif
    }

    /// Track when user reaches notifications screen (Step 4)
    static func trackNotifications() {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "onboarding",
            step: "notifications",
            stepNumber: 4,
            totalSteps: 5
        )

        #if DEBUG
        print("[Onboarding] 📊 Notifications screen (Step 4/5)")
        #endif
    }

    /// Track when onboarding is completed (Step 5)
    static func trackCompletion() {
        AnalyticsManager.shared.trackFunnelCompleted(
            funnel: "onboarding",
            totalSteps: 5,
            metadata: ["completed": true]
        )

        // Save completion to UserDefaults
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(Date(), forKey: "onboardingCompletedDate")

        #if DEBUG
        print("[Onboarding] ✅ Completed (Step 5/5)")
        #endif
    }

    /// Track if user skips onboarding
    static func trackSkip(atScreenIndex: Int, totalScreens: Int, screenID: String) {
        AnalyticsManager.shared.trackFunnelDropoff(
            funnel: "onboarding",
            step: screenID,
            stepNumber: atScreenIndex + 1,
            totalSteps: totalScreens,
            reason: "user_skipped"
        )

        #if DEBUG
        print("[Onboarding] ⏭️ Skipped at: \(screenID)")
        #endif
    }

    /// Track if user drops off (exits without completing)
    static func trackDropoff(atScreenIndex: Int, totalScreens: Int, screenID: String) {
        AnalyticsManager.shared.trackFunnelDropoff(
            funnel: "onboarding",
            step: screenID,
            stepNumber: atScreenIndex + 1,
            totalSteps: totalScreens,
            reason: "user_exited"
        )

        #if DEBUG
        print("[Onboarding] ❌ Dropped off at: \(screenID)")
        #endif
    }
}
