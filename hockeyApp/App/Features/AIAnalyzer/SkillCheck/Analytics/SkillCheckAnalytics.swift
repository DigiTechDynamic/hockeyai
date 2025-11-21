import Foundation

// MARK: - Skill Check Analytics
/// Tracks video-based skill analysis flow
/// This is a comprehensive funnel measuring engagement with AI skill analysis
enum SkillCheckAnalytics {

    // MARK: - Funnel Tracking

    /// Track when user starts Skill Check (Step 1)
    /// Called when user enters Skill Check flow
    static func trackStarted(source: String = "home_screen") {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "skill_check",
            step: "started",
            stepNumber: 1,
            totalSteps: 8,
            metadata: ["source": source]
        )

        #if DEBUG
        print("[Skill Check] 📊 Started from: \(source) (Step 1/8)")
        #endif
    }

    /// Track when video is selected/recorded (Step 2)
    /// - Parameter source: "camera" or "library"
    static func trackVideoSelected(source: String) {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "skill_check",
            step: "video_selected",
            stepNumber: 2,
            totalSteps: 8,
            metadata: ["video_source": source]
        )

        #if DEBUG
        print("[Skill Check] 📊 Video selected: \(source) (Step 2/8)")
        #endif
    }

    /// Track when trim video screen is viewed (Step 3)
    /// - Parameters:
    ///   - videoDuration: Original video duration in seconds
    static func trackTrimViewed(videoDuration: Double) {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "skill_check",
            step: "trim_viewed",
            stepNumber: 3,
            totalSteps: 8,
            metadata: [
                "original_duration": videoDuration
            ]
        )

        #if DEBUG
        print("[Skill Check] 📊 Trim viewed (Step 3/8) - Duration: \(videoDuration)s")
        #endif
    }

    /// Track when video trimming is completed (Step 4)
    /// - Parameters:
    ///   - originalDuration: Original video length
    ///   - trimmedDuration: Final trimmed length
    static func trackTrimCompleted(originalDuration: Double, trimmedDuration: Double) {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "skill_check",
            step: "trim_completed",
            stepNumber: 4,
            totalSteps: 8,
            metadata: [
                "original_duration": originalDuration,
                "trimmed_duration": trimmedDuration,
                "trim_reduction_percent": Int((1 - trimmedDuration/originalDuration) * 100)
            ]
        )

        #if DEBUG
        print("[Skill Check] 📊 Trim completed (Step 4/8) - \(originalDuration)s → \(trimmedDuration)s")
        #endif
    }

    /// Track when AI analysis starts (Step 5)
    static func trackAnalyzing() {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "skill_check",
            step: "analyzing",
            stepNumber: 5,
            totalSteps: 8
        )

        #if DEBUG
        print("[Skill Check] 📊 AI analyzing (Step 5/8)")
        #endif
    }

    /// Track when user views their results (Step 6)
    /// - Parameters:
    ///   - score: The skill score received
    ///   - tier: The tier/level assigned
    ///   - category: Type of skill analyzed
    static func trackResultsViewed(score: Int, tier: String, category: String?) {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "skill_check",
            step: "results_viewed",
            stepNumber: 6,
            totalSteps: 8,
            metadata: [
                "score": score,
                "tier": tier,
                "category": category ?? "unknown"
            ]
        )

        #if DEBUG
        print("[Skill Check] 📊 Results viewed (Step 6/8) - Score: \(score)")
        #endif
    }

    /// Track when user clicks to reveal elite breakdown (Step 7 - Premium Gate)
    /// - Parameters:
    ///   - score: The user's skill score
    ///   - tier: The tier assigned
    ///   - category: Type of skill
    static func trackEliteBreakdownClicked(score: Int, tier: String, category: String?) {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "skill_check",
            step: "elite_breakdown_clicked",
            stepNumber: 7,
            totalSteps: 8,
            metadata: [
                "score": score,
                "tier": tier,
                "category": category ?? "unknown"
            ]
        )

        #if DEBUG
        print("[Skill Check] 📊 Elite breakdown clicked (Step 7/8) - Score: \(score)")
        #endif
    }

    /// Track when user successfully unlocks and views elite breakdown (Step 8 - Completion)
    /// - Parameters:
    ///   - score: The user's skill score
    ///   - tier: The tier assigned
    ///   - category: Type of skill
    static func trackEliteBreakdownUnlocked(score: Int, tier: String, category: String?) {
        AnalyticsManager.shared.trackFunnelCompleted(
            funnel: "skill_check",
            totalSteps: 8,
            metadata: [
                "score": score,
                "tier": tier,
                "category": category ?? "unknown",
                "premium_unlocked": true
            ]
        )

        #if DEBUG
        print("[Skill Check] ✅ Elite breakdown unlocked (Step 8/8) - Score: \(score)")
        #endif
    }

    /// Track when flow completes without premium unlock (Alternative Completion)
    /// Called when user dismisses results without unlocking elite breakdown
    static func trackCompletedWithoutPremium(score: Int, tier: String, category: String?) {
        AnalyticsManager.shared.trackFunnelCompleted(
            funnel: "skill_check",
            totalSteps: 8,
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
            totalSteps: 8,
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

    // MARK: - Helper Methods

    private static func getStepNumber(for step: String) -> Int {
        switch step {
        case "started": return 1
        case "video_selected": return 2
        case "trim_viewed": return 3
        case "trim_completed": return 4
        case "analyzing": return 5
        case "results_viewed": return 6
        case "elite_breakdown_clicked": return 7
        case "elite_breakdown_unlocked": return 8
        default: return 0
        }
    }
}
