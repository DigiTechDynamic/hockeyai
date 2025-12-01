import Foundation

// MARK: - STY Validation Analytics (Onboarding)
/// Tracks the detailed STY validation flow during onboarding
/// 7-step funnel: started → photo_selected → analyzing → results_viewed → rating_preprompt → rating_shown → completed
enum STYValidationAnalytics {

    // MARK: - Funnel Tracking (7 Steps)

    /// Track when user sees photo upload screen (Step 1)
    static func trackStarted() {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "sty_validation",
            step: "started",
            stepNumber: 1,
            totalSteps: 7
        )

        #if DEBUG
        print("[STY Validation] 📊 Started (Step 1/7)")
        #endif
    }

    /// Track when user selects/captures a photo (Step 2)
    /// - Parameter source: "camera" or "library"
    static func trackPhotoSelected(source: String) {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "sty_validation",
            step: "photo_selected",
            stepNumber: 2,
            totalSteps: 7,
            metadata: ["photo_source": source]
        )

        #if DEBUG
        print("[STY Validation] 📊 Photo selected: \(source) (Step 2/7)")
        #endif
    }

    /// Track when AI analysis starts (Step 3)
    static func trackAnalyzing() {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "sty_validation",
            step: "analyzing",
            stepNumber: 3,
            totalSteps: 7
        )

        #if DEBUG
        print("[STY Validation] 📊 AI analyzing (Step 3/7)")
        #endif
    }

    /// Track when user sees results screen (Step 4)
    /// - Parameters:
    ///   - score: The STY score received
    ///   - tier: The tier/archetype assigned
    static func trackResultsViewed(score: Int, tier: String) {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "sty_validation",
            step: "results_viewed",
            stepNumber: 4,
            totalSteps: 7,
            metadata: [
                "score": score,
                "tier": tier
            ]
        )

        #if DEBUG
        print("[STY Validation] 📊 Results viewed (Step 4/7) - Score: \(score), Tier: \(tier)")
        #endif
    }

    /// Track when user sees Greeny's rating pre-prompt (Step 5)
    static func trackRatingPreprompt() {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "sty_validation",
            step: "rating_preprompt",
            stepNumber: 5,
            totalSteps: 7
        )

        #if DEBUG
        print("[STY Validation] 📊 Rating pre-prompt shown (Step 5/7)")
        #endif
    }

    /// Track when iOS rating popup is displayed (Step 6)
    static func trackRatingShown() {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "sty_validation",
            step: "rating_shown",
            stepNumber: 6,
            totalSteps: 7
        )

        #if DEBUG
        print("[STY Validation] 📊 iOS rating popup shown (Step 6/7)")
        #endif
    }

    /// Track when STY validation completes (Step 7)
    /// User has responded to rating (either accepted or skipped)
    /// - Parameter ratingAccepted: Whether user tapped "Yeah, I got you" or "Maybe later"
    static func trackCompleted(ratingAccepted: Bool) {
        AnalyticsManager.shared.trackFunnelCompleted(
            funnel: "sty_validation",
            totalSteps: 7,
            metadata: [
                "rating_accepted": ratingAccepted
            ]
        )

        #if DEBUG
        print("[STY Validation] ✅ Completed (Step 7/7) - Rating accepted: \(ratingAccepted)")
        #endif
    }

    // MARK: - Additional Events (Non-Funnel)

    /// Track when analysis fails
    /// - Parameter error: Error description
    static func trackAnalysisFailed(error: String) {
        AnalyticsManager.shared.track(
            eventName: "sty_validation_analysis_failed",
            properties: [
                "error": error,
                "context": "onboarding"
            ]
        )

        #if DEBUG
        print("[STY Validation] ❌ Analysis failed: \(error)")
        #endif
    }

    /// Track when user abandons the flow
    /// - Parameter step: Which step they were on
    static func trackAbandoned(step: String) {
        AnalyticsManager.shared.trackFunnelDropoff(
            funnel: "sty_validation",
            step: step,
            stepNumber: getStepNumber(for: step),
            totalSteps: 7,
            reason: "user_abandoned"
        )

        #if DEBUG
        print("[STY Validation] ⏹️ Abandoned at: \(step)")
        #endif
    }

    // MARK: - Helper Methods

    private static func getStepNumber(for step: String) -> Int {
        switch step {
        case "started": return 1
        case "photo_selected": return 2
        case "analyzing": return 3
        case "results_viewed": return 4
        case "rating_preprompt": return 5
        case "rating_shown": return 6
        case "completed": return 7
        default: return 0
        }
    }
}
