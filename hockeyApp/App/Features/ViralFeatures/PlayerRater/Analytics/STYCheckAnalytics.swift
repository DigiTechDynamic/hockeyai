import Foundation

// MARK: - STY Check Analytics (Post-Onboarding)
/// Tracks STY checks initiated from home screen or profile
/// This is Funnel 3: Measures feature engagement after onboarding
enum STYCheckAnalytics {

    // MARK: - Funnel Tracking

    /// Track when user starts STY check from home (Step 1)
    /// Called when user taps STY Check feature from home/profile
    static func trackStarted(source: String = "home_screen") {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "sty_check",
            step: "started",
            stepNumber: 1,
            totalSteps: 7,
            metadata: ["source": source]
        )

        #if DEBUG
        print("[STY Check] 📊 Started from: \(source) (Step 1/7)")
        #endif
    }

    /// Track when photo picker opens (Step 2)
    /// - Parameter source: "camera" or "library"
    static func trackPickerOpened(source: String) {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "sty_check",
            step: "picker_opened",
            stepNumber: 2,
            totalSteps: 7,
            metadata: ["picker_source": source]
        )

        #if DEBUG
        print("[STY Check] 📊 Picker opened: \(source) (Step 2/7)")
        #endif
    }

    /// Track when user selects/captures a photo (Step 3)
    /// - Parameter source: "camera" or "library"
    static func trackPhotoSelected(source: String) {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "sty_check",
            step: "photo_selected",
            stepNumber: 3,
            totalSteps: 7,
            metadata: ["photo_source": source]
        )

        #if DEBUG
        print("[STY Check] 📊 Photo selected: \(source) (Step 3/7)")
        #endif
    }

    /// Track when AI analysis starts (Step 4)
    static func trackAnalyzing() {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "sty_check",
            step: "analyzing",
            stepNumber: 4,
            totalSteps: 7
        )

        #if DEBUG
        print("[STY Check] 📊 AI analyzing (Step 4/7)")
        #endif
    }

    /// Track when user views their results (Step 5)
    /// - Parameters:
    ///   - score: The STY score received
    ///   - tier: The tier/archetype assigned
    static func trackResultsViewed(score: Int, tier: String) {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "sty_check",
            step: "results_viewed",
            stepNumber: 5,
            totalSteps: 7,
            metadata: [
                "score": score,
                "tier": tier
            ]
        )

        #if DEBUG
        print("[STY Check] 📊 Results viewed (Step 5/7) - Score: \(score)")
        #endif
    }

    /// Track when user clicks to reveal beauty breakdown (Step 6 - Premium Gate)
    /// - Parameters:
    ///   - score: The user's STY score
    ///   - tier: The tier/archetype assigned
    static func trackBeautyBreakdownClicked(score: Int, tier: String) {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "sty_check",
            step: "beauty_breakdown_clicked",
            stepNumber: 6,
            totalSteps: 7,
            metadata: [
                "score": score,
                "tier": tier
            ]
        )

        #if DEBUG
        print("[STY Check] 📊 Beauty breakdown clicked (Step 6/7) - Score: \(score)")
        #endif
    }

    /// Track when user successfully unlocks and views premium breakdown (Step 7 - Completion)
    /// - Parameters:
    ///   - score: The user's STY score
    ///   - tier: The tier/archetype assigned
    static func trackBeautyBreakdownUnlocked(score: Int, tier: String) {
        AnalyticsManager.shared.trackFunnelCompleted(
            funnel: "sty_check",
            totalSteps: 7,
            metadata: [
                "score": score,
                "tier": tier,
                "premium_unlocked": true
            ]
        )

        #if DEBUG
        print("[STY Check] ✅ Beauty breakdown unlocked (Step 7/7) - Score: \(score)")
        #endif
    }

    /// Track when user shares their results (Alternative Completion)
    /// - Parameters:
    ///   - score: The score being shared
    ///   - shareMethod: How they shared (instagram, snapchat, etc.)
    static func trackShared(score: Int, shareMethod: String = "unknown") {
        AnalyticsManager.shared.trackFunnelCompleted(
            funnel: "sty_check",
            totalSteps: 7,
            metadata: [
                "score": score,
                "share_method": shareMethod,
                "shared": true
            ]
        )

        #if DEBUG
        print("[STY Check] ✅ Shared - Method: \(shareMethod)")
        #endif
    }

    /// Track when flow completes without premium unlock or sharing (Alternative Completion)
    /// Called when user dismisses results without unlocking premium or sharing
    static func trackCompletedWithoutPremium(score: Int, tier: String) {
        AnalyticsManager.shared.trackFunnelCompleted(
            funnel: "sty_check",
            totalSteps: 7,
            metadata: [
                "score": score,
                "tier": tier,
                "premium_unlocked": false,
                "shared": false
            ]
        )

        #if DEBUG
        print("[STY Check] ✅ Completed without premium")
        #endif
    }

    // MARK: - Additional Events (Non-Funnel)

    /// Track when analysis fails
    /// - Parameter error: Error description
    static func trackAnalysisFailed(error: String) {
        AnalyticsManager.shared.track(
            eventName: "sty_check_analysis_failed",
            properties: [
                "error": error,
                "context": "home_screen"
            ]
        )

        #if DEBUG
        print("[STY Check] ❌ Analysis failed: \(error)")
        #endif
    }

    /// Track when user abandons the flow
    /// - Parameters:
    ///   - step: Which step they were on
    ///   - duration: How long before abandoning
    static func trackAbandoned(step: String, duration: TimeInterval) {
        AnalyticsManager.shared.trackFunnelDropoff(
            funnel: "sty_check",
            step: step,
            stepNumber: getStepNumber(for: step),
            totalSteps: 7,
            reason: "user_abandoned"
        )

        #if DEBUG
        print("[STY Check] ⏹️ Abandoned at: \(step)")
        #endif
    }

    /// Track when user tries again after seeing results
    /// - Parameter previousScore: Their previous score
    static func trackTryAgain(previousScore: Int) {
        AnalyticsManager.shared.track(
            eventName: "sty_check_try_again",
            properties: [
                "previous_score": previousScore,
                "context": "home_screen"
            ]
        )

        #if DEBUG
        print("[STY Check] 🔄 Try again - Previous score: \(previousScore)")
        #endif
    }

    // MARK: - Helper Methods

    private static func getStepNumber(for step: String) -> Int {
        switch step {
        case "started": return 1
        case "picker_opened": return 2
        case "photo_selected": return 3
        case "analyzing": return 4
        case "results_viewed": return 5
        case "beauty_breakdown_clicked": return 6
        case "beauty_breakdown_unlocked": return 7
        default: return 0
        }
    }
}
