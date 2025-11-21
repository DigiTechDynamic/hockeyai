import Foundation

// MARK: - STY Validation Analytics (Onboarding)
/// Tracks the detailed STY validation flow during onboarding
/// This is Funnel 2: Deep-dive into the STY validation process to diagnose drop-offs
enum STYValidationAnalytics {

    // MARK: - Funnel Tracking

    /// Track when user starts STY validation (Step 1)
    /// Called when user taps "Get Validated" button
    static func trackStarted() {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "sty_validation",
            step: "started",
            stepNumber: 1,
            totalSteps: 5
        )

        #if DEBUG
        print("[STY Validation] 📊 Started (Step 1/5)")
        #endif
    }

    /// Track when photo picker opens (Step 2)
    /// CRITICAL: This diagnoses the 47% drop-off
    /// - Parameter source: "camera" or "library"
    static func trackPickerOpened(source: String) {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "sty_validation",
            step: "picker_opened",
            stepNumber: 2,
            totalSteps: 5,
            metadata: ["picker_source": source]
        )

        #if DEBUG
        print("[STY Validation] 📊 Picker opened: \(source) (Step 2/5)")
        #endif
    }

    /// Track when user selects/captures a photo (Step 3)
    /// - Parameter source: "camera" or "library"
    static func trackPhotoSelected(source: String) {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "sty_validation",
            step: "photo_selected",
            stepNumber: 3,
            totalSteps: 5,
            metadata: ["photo_source": source]
        )

        #if DEBUG
        print("[STY Validation] 📊 Photo selected: \(source) (Step 3/5)")
        #endif
    }

    /// Track when AI analysis starts (Step 4)
    static func trackAnalyzing() {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "sty_validation",
            step: "analyzing",
            stepNumber: 4,
            totalSteps: 5
        )

        #if DEBUG
        print("[STY Validation] 📊 AI analyzing (Step 4/5)")
        #endif
    }

    /// Track when STY validation completes (Step 5)
    /// User has seen results and accepted/continued
    /// - Parameters:
    ///   - score: The STY score received
    ///   - tier: The tier/archetype assigned
    ///   - duration: How long the entire flow took
    static func trackCompleted(score: Int, tier: String, duration: TimeInterval) {
        AnalyticsManager.shared.trackFunnelCompleted(
            funnel: "sty_validation",
            totalSteps: 5,
            metadata: [
                "score": score,
                "tier": tier,
                "duration_seconds": Int(duration)
            ]
        )

        #if DEBUG
        print("[STY Validation] ✅ Completed (Step 5/5) - Score: \(score), Tier: \(tier)")
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
    /// - Parameters:
    ///   - step: Which step they were on
    ///   - duration: How long before abandoning
    static func trackAbandoned(step: String, duration: TimeInterval) {
        AnalyticsManager.shared.trackFunnelDropoff(
            funnel: "sty_validation",
            step: step,
            stepNumber: getStepNumber(for: step),
            totalSteps: 5,
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
        case "picker_opened": return 2
        case "photo_selected": return 3
        case "analyzing": return 4
        case "completed": return 5
        default: return 0
        }
    }
}
