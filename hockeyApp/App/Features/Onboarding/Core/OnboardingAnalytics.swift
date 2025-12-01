import Foundation

// MARK: - Onboarding Analytics
// 6-step funnel: started → welcome → sty_check → rating_screen → notification_screen → completed
// This allows tracking drop-offs at every screen

enum OnboardingAnalytics {

    // MARK: - Funnel Tracking (6 Steps)

    /// Track when onboarding starts (Step 1)
    static func trackStart() {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "onboarding",
            step: "started",
            stepNumber: 1,
            totalSteps: 6
        )

        #if DEBUG
        print("[Onboarding] 📊 Started (Step 1/6)")
        #endif
    }

    /// Track when user views welcome screen (Step 2)
    static func trackWelcome() {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "onboarding",
            step: "welcome",
            stepNumber: 2,
            totalSteps: 6
        )

        #if DEBUG
        print("[Onboarding] 📊 Welcome screen (Step 2/6)")
        #endif
    }

    /// Track when user reaches STY Check screen (Step 3)
    static func trackSTYCheck() {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "onboarding",
            step: "sty_check",
            stepNumber: 3,
            totalSteps: 6
        )

        #if DEBUG
        print("[Onboarding] 📊 STY Check screen (Step 3/6)")
        #endif
    }

    /// Track when user reaches app rating screen (Step 4)
    static func trackRatingScreen() {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "onboarding",
            step: "rating_screen",
            stepNumber: 4,
            totalSteps: 6
        )

        #if DEBUG
        print("[Onboarding] 📊 Rating screen (Step 4/6)")
        #endif
    }

    /// Track rating pre-prompt response (supplementary event)
    static func trackRatingResponse(accepted: Bool) {
        AnalyticsManager.shared.track(
            eventName: "onboarding_rating_response",
            properties: [
                "accepted": accepted,
                "response": accepted ? "accepted" : "skipped"
            ]
        )

        #if DEBUG
        print("[Onboarding] 📊 Rating response: \(accepted ? "accepted" : "skipped")")
        #endif
    }

    /// Track when user reaches notification screen (Step 5)
    static func trackNotificationScreen() {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "onboarding",
            step: "notification_screen",
            stepNumber: 5,
            totalSteps: 6
        )

        #if DEBUG
        print("[Onboarding] 📊 Notification screen (Step 5/6)")
        #endif
    }

    /// Track notification permission response (supplementary event)
    static func trackNotificationResponse(allowed: Bool) {
        AnalyticsManager.shared.track(
            eventName: "onboarding_notification_response",
            properties: [
                "allowed": allowed,
                "response": allowed ? "allowed" : "denied"
            ]
        )

        #if DEBUG
        print("[Onboarding] 📊 Notification response: \(allowed ? "allowed" : "denied")")
        #endif
    }

    /// Track when onboarding is completed (Step 6)
    static func trackCompletion() {
        AnalyticsManager.shared.trackFunnelCompleted(
            funnel: "onboarding",
            totalSteps: 6,
            metadata: ["completed": true]
        )

        // Save completion to UserDefaults
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(Date(), forKey: "onboardingCompletedDate")

        #if DEBUG
        print("[Onboarding] ✅ Completed (Step 6/6)")
        #endif
    }
}
