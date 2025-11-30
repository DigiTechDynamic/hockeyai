import Foundation

// MARK: - Skill Check Analytics
/// Tracks video-based skill analysis flow
/// SIMPLIFIED FUNNEL (5 steps):
/// 1. Started (capture screen) → 2. Video selected → 3. Analyzing → 4. Results → 5. Premium unlock
enum SkillCheckAnalytics {

    // MARK: - Funnel Tracking

    /// Track when user opens the capture screen (Step 1)
    /// Called when capture screen appears
    static func trackStarted(source: String = "skill_check_capture") {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "skill_check",
            step: "started",
            stepNumber: 1,
            totalSteps: 5,
            metadata: ["source": source]
        )

        #if DEBUG
        print("[Skill Check] 📊 Started from: \(source) (Step 1/5)")
        #endif
    }

    /// Track when video is selected/recorded (Step 2)
    /// - Parameter source: "camera" or "library"
    static func trackVideoSelected(source: String) {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "skill_check",
            step: "video_selected",
            stepNumber: 2,
            totalSteps: 5,
            metadata: ["video_source": source]
        )

        #if DEBUG
        print("[Skill Check] 📊 Video selected: \(source) (Step 2/5)")
        #endif
    }

    /// Track when AI analysis starts (Step 3)
    static func trackAnalyzing() {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "skill_check",
            step: "analyzing",
            stepNumber: 3,
            totalSteps: 5
        )

        #if DEBUG
        print("[Skill Check] 📊 AI analyzing (Step 3/5)")
        #endif
    }

    /// Track when user views their results (Step 4)
    /// - Parameters:
    ///   - score: The skill score received
    ///   - tier: The tier/level assigned
    ///   - category: Type of skill analyzed
    static func trackResultsViewed(score: Int, tier: String, category: String?) {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "skill_check",
            step: "results_viewed",
            stepNumber: 4,
            totalSteps: 5,
            metadata: [
                "score": score,
                "tier": tier,
                "category": category ?? "unknown"
            ]
        )

        #if DEBUG
        print("[Skill Check] 📊 Results viewed (Step 4/5) - Score: \(score)")
        #endif
    }

    /// Track when user clicks to reveal elite breakdown (Premium Gate)
    /// - Parameters:
    ///   - score: The user's skill score
    ///   - tier: The tier assigned
    ///   - category: Type of skill
    static func trackEliteBreakdownClicked(score: Int, tier: String, category: String?) {
        AnalyticsManager.shared.track(
            eventName: "skill_check_elite_breakdown_clicked",
            properties: [
                "score": score,
                "tier": tier,
                "category": category ?? "unknown"
            ]
        )

        #if DEBUG
        print("[Skill Check] 📊 Elite breakdown clicked - Score: \(score)")
        #endif
    }

    /// Track when user successfully unlocks elite breakdown (Step 5 - Completion)
    /// - Parameters:
    ///   - score: The user's skill score
    ///   - tier: The tier assigned
    ///   - category: Type of skill
    static func trackEliteBreakdownUnlocked(score: Int, tier: String, category: String?) {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "skill_check",
            step: "elite_breakdown_unlocked",
            stepNumber: 5,
            totalSteps: 5,
            metadata: [
                "score": score,
                "tier": tier,
                "category": category ?? "unknown",
                "premium_unlocked": true
            ]
        )

        AnalyticsManager.shared.trackFunnelCompleted(
            funnel: "skill_check",
            totalSteps: 5,
            metadata: [
                "score": score,
                "tier": tier,
                "category": category ?? "unknown",
                "premium_unlocked": true
            ]
        )

        #if DEBUG
        print("[Skill Check] ✅ Elite breakdown unlocked (Step 5/5) - Score: \(score)")
        #endif
    }

    /// Track when flow completes without premium unlock (Alternative Completion)
    /// Called when user dismisses results without unlocking elite breakdown
    static func trackCompletedWithoutPremium(score: Int, tier: String, category: String?) {
        AnalyticsManager.shared.trackFunnelCompleted(
            funnel: "skill_check",
            totalSteps: 5,
            metadata: [
                "score": score,
                "tier": tier,
                "category": category ?? "unknown",
                "premium_unlocked": false
            ]
        )

        #if DEBUG
        print("[Skill Check] ✅ Completed without premium")
        #endif
    }

    // MARK: - Legacy Methods (Deprecated)

    /// Track when user views the hero screen
    /// @available(*, deprecated, message: "Hero screen removed from new flow")
    static func trackHeroViewed() {
        // No-op in new flow - redirect to trackStarted
        #if DEBUG
        print("[Skill Check] ⚠️ trackHeroViewed called but hero screen is removed")
        #endif
    }

    // MARK: - Additional Events (Non-Funnel)

    /// Track when analysis fails
    /// - Parameter error: Error description
    static func trackAnalysisFailed(error: String) {
        AnalyticsManager.shared.track(
            eventName: "skill_check_analysis_failed",
            properties: [
                "error": error,
                "feature": "skill_check"
            ]
        )

        #if DEBUG
        print("[Skill Check] ❌ Analysis failed: \(error)")
        #endif
    }

    /// Track when user abandons the flow
    /// - Parameters:
    ///   - step: Which step they were on
    ///   - duration: How long before abandoning
    static func trackAbandoned(step: String, duration: TimeInterval) {
        AnalyticsManager.shared.trackFunnelDropoff(
            funnel: "skill_check",
            step: step,
            stepNumber: getStepNumber(for: step),
            totalSteps: 6,
            reason: "user_abandoned"
        )

        #if DEBUG
        print("[Skill Check] ⏹️ Abandoned at: \(step)")
        #endif
    }

    /// Track when video is rejected (too long, invalid, etc.)
    /// - Parameters:
    ///   - reason: Why video was rejected
    ///   - videoDuration: Length of video
    static func trackVideoRejected(reason: String, videoDuration: Double?) {
        AnalyticsManager.shared.track(
            eventName: "skill_check_video_rejected",
            properties: [
                "reason": reason,
                "video_duration": videoDuration ?? 0
            ]
        )

        #if DEBUG
        print("[Skill Check] ❌ Video rejected: \(reason)")
        #endif
    }

    // MARK: - Legacy Methods (Deprecated but kept for compatibility)

    /// Track when trim video screen is viewed
    /// @available(*, deprecated, message: "Trim step removed from new flow")
    static func trackTrimViewed(videoDuration: Double) {
        // No-op in new flow
        #if DEBUG
        print("[Skill Check] ⚠️ trackTrimViewed called but trim step is removed")
        #endif
    }

    /// Track when video trimming is completed
    /// @available(*, deprecated, message: "Trim step removed from new flow")
    static func trackTrimCompleted(originalDuration: Double, trimmedDuration: Double) {
        // No-op in new flow
        #if DEBUG
        print("[Skill Check] ⚠️ trackTrimCompleted called but trim step is removed")
        #endif
    }

    // MARK: - Helper Methods

    private static func getStepNumber(for step: String) -> Int {
        switch step {
        case "started": return 1
        case "video_selected": return 2
        case "analyzing": return 3
        case "results_viewed": return 4
        case "elite_breakdown_unlocked": return 5
        default: return 0
        }
    }
}
